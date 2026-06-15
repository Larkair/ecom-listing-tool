-- =====================================================
-- V49: 一次性清理 product-images 中所有旧文件
-- 在 Supabase Dashboard → SQL Editor 中执行
--
-- ⚠️ 警告：此脚本会删除 product-images 中的所有文件！
--    执行前请确认不再需要这些图片的公开链接。
--
-- 注意：此脚本使用 pg_net + Edge Function 来删除，
--       不能直接 SQL 删 storage.objects（只删元数据不删S3文件）
-- =====================================================

-- 先查看当前 product-images 中有多少文件，以及总大小
SELECT
  count(*) AS file_count,
  sum((metadata->>'size')::bigint) AS total_size_bytes,
  pg_size_pretty(sum((metadata->>'size')::bigint)::bigint) AS total_size_human,
  min(created_at) AS oldest_file,
  max(created_at) AS newest_file
FROM storage.objects
WHERE bucket_id = 'product-images';

-- =====================================================
-- 手动清理方式（3选1）：
--
-- 方式1（推荐）：Dashboard 手动删除
--   Supabase Dashboard → Storage → product-images
--   → 全选所有文件 → 点击 Delete
--
-- 方式2：部署 Edge Function 后手动调用
--   supabase functions deploy cleanup-expired-images
--   然后在浏览器访问（需替换 <PROJECT_REF>）：
--   https://<PROJECT_REF>.supabase.co/functions/v1/cleanup-expired-images
--
-- 方式3：用 Supabase CLI 批量删除
--   supabase storage rm --recursive product-images/products/
-- =====================================================
