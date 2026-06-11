-- =====================================================
-- Supabase Storage Bucket 创建脚本
-- 在 Supabase Dashboard → SQL Editor 中执行
-- =====================================================

-- 创建 product-images Bucket（Public 公开访问）
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'product-images',
  'product-images',
  true,
  52428800,
  '{"image/jpeg","image/png","image/gif","image/webp","image/bmp","image/tiff"}'
)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 验证
SELECT name, public, file_size_limit FROM storage.buckets WHERE name = 'product-images';
