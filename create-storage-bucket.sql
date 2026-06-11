-- =====================================================
-- Supabase Storage Bucket 创建脚本
-- 在 Supabase Dashboard → SQL Editor 中执行此脚本
-- =====================================================

-- 1. 创建 product-images Bucket（Public 公开访问）
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'product-images',
  'product-images',
  true,
  52428800,  -- 50MB 单文件上限
  '{"image/jpeg","image/png","image/gif","image/webp","image/bmp","image/tiff"}'
)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. 删除可能残留的旧策略（避免冲突）
DELETE FROM storage.policies
WHERE bucket_id = (SELECT id FROM storage.buckets WHERE name = 'product-images')
  AND name IN ('anon_insert_product_images', 'anon_select_product_images');

-- 3. 添加 INSERT 策略：允许匿名用户上传图片
INSERT INTO storage.policies (name, bucket_id, operation, definition, roles)
SELECT
  'anon_insert_product_images',
  b.id,
  'INSERT',
  'true',
  '{anon}'
FROM storage.buckets b
WHERE b.name = 'product-images';

-- 4. 添加 SELECT 策略：允许公开读取图片
INSERT INTO storage.policies (name, bucket_id, operation, definition, roles)
SELECT
  'anon_select_product_images',
  b.id,
  'SELECT',
  'true',
  '{anon}'
FROM storage.buckets b
WHERE b.name = 'product-images';

-- 5. 验证结果
SELECT
  b.name AS bucket_name,
  b.public,
  COUNT(p.id) AS policy_count,
  string_agg(p.name || '(' || p.operation || ')', ', ') AS policies
FROM storage.buckets b
LEFT JOIN storage.policies p ON p.bucket_id = b.id
WHERE b.name = 'product-images'
GROUP BY b.name, b.public;
