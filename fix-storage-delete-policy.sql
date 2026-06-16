-- =====================================================
-- V49: 为 product-images bucket 添加 DELETE 权限
-- 在 Supabase Dashboard → SQL Editor 中执行
--
-- 之前只有 SELECT/INSERT/UPDATE 策略，缺少 DELETE
-- 导致匿名用户无法通过 Storage API 删除文件
-- =====================================================

-- 允许 anon 用户删除 product-images 中的文件
CREATE POLICY "Allow anon delete on product-images"
ON storage.objects
FOR DELETE
USING (bucket_id = 'product-images');

-- 如果上面的语句报错 "policy already exists"，说明已有该策略，
-- 那问题出在其他地方，建议直接用「删除 bucket 再重建」的方式清理
