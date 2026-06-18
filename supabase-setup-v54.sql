-- ================================================
-- V54: Supabase Storage 初始化脚本
-- 请在 Supabase Dashboard → SQL Editor 中执行
-- ================================================

-- 1. 创建 ecom-assets bucket（模板文件、方案文件等）
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('ecom-assets', 'ecom-assets', true, 10485760, 
  ARRAY['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'image/jpeg', 'image/png', 'image/webp', 'application/json'])
ON CONFLICT (id) DO UPDATE SET public = true, file_size_limit = 10485760;

-- 2. 创建 product-images bucket（产品图片）
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('product-images', 'product-images', true, 10485760, 
  ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET public = true, file_size_limit = 10485760;

-- 3. ecom-assets RLS 策略 — anon 可以上传、下载、删除
CREATE POLICY "ecom-assets anon upload" ON storage.objects
  FOR INSERT TO anon
  WITH CHECK (bucket_id = 'ecom-assets');

CREATE POLICY "ecom-assets anon download" ON storage.objects
  FOR SELECT TO anon
  USING (bucket_id = 'ecom-assets');

CREATE POLICY "ecom-assets anon delete" ON storage.objects
  FOR DELETE TO anon
  USING (bucket_id = 'ecom-assets');

CREATE POLICY "ecom-assets anon update" ON storage.objects
  FOR UPDATE TO anon
  USING (bucket_id = 'ecom-assets')
  WITH CHECK (bucket_id = 'ecom-assets');

-- 4. product-images RLS 策略 — anon 可以上传、下载、删除
CREATE POLICY "product-images anon upload" ON storage.objects
  FOR INSERT TO anon
  WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "product-images anon download" ON storage.objects
  FOR SELECT TO anon
  USING (bucket_id = 'product-images');

CREATE POLICY "product-images anon delete" ON storage.objects
  FOR DELETE TO anon
  USING (bucket_id = 'product-images');

CREATE POLICY "product-images anon update" ON storage.objects
  FOR UPDATE TO anon
  USING (bucket_id = 'product-images')
  WITH CHECK (bucket_id = 'product-images');

-- 5. 确认 ecom_config_schemes 表包含所有必要列
-- (如果缺少列，之前的 PGRST204 错误会导致方案无法跨浏览器共享)
-- V52 已添加 template_library_id，这里确认其他必要列
ALTER TABLE ecom_config_schemes ADD COLUMN IF NOT EXISTS template_storage_path TEXT DEFAULT '';
ALTER TABLE ecom_config_schemes ADD COLUMN IF NOT EXISTS template_library_id TEXT DEFAULT '';
ALTER TABLE ecom_config_schemes ADD COLUMN IF NOT EXISTS template_meta JSONB DEFAULT '{}';

-- 6. 清理：删除之前测试留下的无用数据（可选）
-- DELETE FROM ecom_config_schemes WHERE scheme_name = 'test_v54';

-- 执行完成后，请在浏览器中强制刷新（Ctrl+Shift+R）测试
