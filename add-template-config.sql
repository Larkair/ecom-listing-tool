-- =============================================
-- 新增 template_config 字段（保存模板写入配置）
-- 执行方式：Supabase Dashboard → SQL Editor → 粘贴运行
-- =============================================

-- 1. ecom_configs 表新增 template_config JSONB 字段
ALTER TABLE ecom_configs
  ADD COLUMN IF NOT EXISTS template_config JSONB DEFAULT NULL;

-- 2. ecom_config_schemes 表新增 template_config JSONB 字段
ALTER TABLE ecom_config_schemes
  ADD COLUMN IF NOT EXISTS template_config JSONB DEFAULT NULL;

-- 3. 验证字段是否创建成功
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name IN ('ecom_configs', 'ecom_config_schemes')
  AND column_name = 'template_config';
