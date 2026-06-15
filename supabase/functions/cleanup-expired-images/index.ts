// =============================================
// Supabase Edge Function: cleanup-expired-images
// 功能：删除 product-images bucket 中超过 24 小时的图片
// 部署方式：supabase functions deploy cleanup-expired-images
// 自动触发：通过 Supabase Cron 每小时调用一次
// =============================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  // 从环境变量获取 Supabase URL 和 Service Role Key
  // 注意：Edge Function 自动注入 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  try {
    const bucketName = 'product-images'
    const expiredHours = 24

    // 计算过期时间点
    const expiredAt = new Date()
    expiredAt.setHours(expiredAt.getHours() - expiredHours)

    // 1. 查询 storage.objects 中超过 24 小时的文件
    // 注意：需要 service_role 权限才能查询 storage schema
    const { data: oldFiles, error: queryError } = await supabase
      .from('storage.objects')
      .select('id, name, bucket_id')
      .eq('bucket_id', bucketName)
      .lt('created_at', expiredAt.toISOString())
      .limit(500) // 每次最多处理 500 个

    if (queryError) {
      console.error('查询过期文件失败:', queryError)
      return new Response(JSON.stringify({
        success: false,
        error: '查询失败: ' + queryError.message
      }), { status: 500, headers: { 'Content-Type': 'application/json' } })
    }

    if (!oldFiles || oldFiles.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        message: '没有过期文件需要清理',
        deleted: 0
      }), { headers: { 'Content-Type': 'application/json' } })
    }

    // 2. 通过 Storage API 删除过期文件（必须用 API 删除，不能直接 SQL 删 storage.objects）
    const fileNames = oldFiles.map(f => f.name)
    const { error: deleteError } = await supabase.storage
      .from(bucketName)
      .remove(fileNames)

    if (deleteError) {
      console.error('删除文件失败:', deleteError)
      // 尝试逐个删除（批量删除可能有文件已被删）
      let successCount = 0
      let failCount = 0
      for (const fileName of fileNames) {
        const { error: singleErr } = await supabase.storage
          .from(bucketName)
          .remove([fileName])
        if (singleErr) {
          failCount++
        } else {
          successCount++
        }
      }
      return new Response(JSON.stringify({
        success: true,
        message: '部分清理完成（批量删除失败后逐个重试）',
        deleted: successCount,
        failed: failCount,
        total: fileNames.length
      }), { headers: { 'Content-Type': 'application/json' } })
    }

    console.log(`清理完成：删除了 ${fileNames.length} 个过期图片`)

    return new Response(JSON.stringify({
      success: true,
      message: '清理完成',
      deleted: fileNames.length
    }), { headers: { 'Content-Type': 'application/json' } })

  } catch (err) {
    console.error('Edge Function 异常:', err)
    return new Response(JSON.stringify({
      success: false,
      error: err.message
    }), { status: 500, headers: { 'Content-Type': 'application/json' } })
  }
})
