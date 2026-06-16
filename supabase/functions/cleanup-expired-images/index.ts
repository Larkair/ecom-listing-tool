Deno.serve(async (req) => {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(JSON.stringify({
      success: false, error: 'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY'
    }), { status: 500, headers: { 'Content-Type': 'application/json' } })
  }

  try {
    const bucketName = 'product-images'
    const expiredHours = 24
    const expiredAt = new Date()
    expiredAt.setHours(expiredAt.getHours() - expiredHours)

    // 1. Query expired files from storage.objects (requires service_role)
    const { data: oldFiles, error: queryError } = await fetch(
      supabaseUrl + '/rest/v1/storage.objects?bucket_id=eq.' + bucketName +
      '&created_at=lt.' + expiredAt.toISOString() +
      '&select=id,name,created_at&order=created_at.asc&limit=500',
      {
        headers: {
          'apikey': serviceRoleKey,
          'Authorization': 'Bearer ' + serviceRoleKey,
          'Content-Type': 'application/json'
        }
      }
    ).then(r => r.json())

    if (queryError) {
      console.error('Query error:', JSON.stringify(queryError))
      return new Response(JSON.stringify({
        success: false, error: 'Query failed: ' + JSON.stringify(queryError)
      }), { status: 500, headers: { 'Content-Type': 'application/json' } })
    }

    if (!oldFiles || oldFiles.length === 0) {
      return new Response(JSON.stringify({
        success: true, message: 'No expired files to clean up', deleted: 0
      }), { headers: { 'Content-Type': 'application/json' } })
    }

    const fileNames = oldFiles.map((f: { name: string }) => f.name)
    console.log(`Found ${fileNames.length} expired files to clean up`)

    // 2. Delete via Storage API remove endpoint (batch)
    const { error: deleteError } = await fetch(
      supabaseUrl + '/storage/v1/object/' + encodeURIComponent(bucketName) + '/delete',
      {
        method: 'POST',
        headers: {
          'apikey': serviceRoleKey,
          'Authorization': 'Bearer ' + serviceRoleKey,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ prefixes: fileNames })
      }
    ).then(r => r.json())

    if (deleteError && deleteError.length > 0) {
      console.warn('Batch delete failed, retrying individually:', JSON.stringify(deleteError))
      // Fallback: delete one by one via Storage API
      let deleted = 0
      let failed = 0
      for (const name of fileNames) {
        const res = await fetch(
          supabaseUrl + '/storage/v1/object/' +
          encodeURIComponent(bucketName + '/' + name),
          {
            method: 'DELETE',
            headers: {
              'apikey': serviceRoleKey,
              'Authorization': 'Bearer ' + serviceRoleKey
            }
          }
        )
        if (res.ok) deleted++
        else {
          failed++
          console.warn('Failed to delete:', name, await res.text())
        }
      }
      return new Response(JSON.stringify({
        success: true, message: 'Partial cleanup (batch failed, retried individually)',
        deleted, failed, total: fileNames.length
      }), { headers: { 'Content-Type': 'application/json' } })
    }

    console.log(`Cleanup done: deleted ${fileNames.length} expired images`)

    return new Response(JSON.stringify({
      success: true,
      message: `Cleanup complete: deleted ${fileNames.length} files older than ${expiredHours}h`,
      deleted: fileNames.length,
      oldestFile: oldFiles[0]?.created_at || null,
      newestFile: oldFiles[oldFiles.length - 1]?.created_at || null
    }), { headers: { 'Content-Type': 'application/json' } })

  } catch (err) {
    console.error('Edge Function error:', err)
    return new Response(JSON.stringify({
      success: false, error: err.message
    }), { status: 500, headers: { 'Content-Type': 'application/json' } })
  }
})
