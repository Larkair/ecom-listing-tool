-- ============================================
-- 跨境电商批量上架工具 - Supabase 数据库 Schema
-- 请在 Supabase SQL Editor 中运行此脚本
-- ============================================

-- 1. 字段配置表
CREATE TABLE IF NOT EXISTS ecom_configs (
  id BIGSERIAL PRIMARY KEY,
  platform TEXT NOT NULL UNIQUE,
  template_filename TEXT,
  template_headers JSONB DEFAULT '[]'::jsonb,
  field_configs JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 产品表
CREATE TABLE IF NOT EXISTS ecom_products (
  id BIGSERIAL PRIMARY KEY,
  platform TEXT NOT NULL,
  name TEXT DEFAULT '新产品',
  product_data JSONB DEFAULT '{}'::jsonb,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 全局设置表
CREATE TABLE IF NOT EXISTS ecom_settings (
  id BIGSERIAL PRIMARY KEY DEFAULT 1,
  settings_data JSONB DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 插入默认设置
INSERT INTO ecom_settings (id, settings_data) VALUES (1, '{
  "maxTitleLen": 120,
  "genCount": 5,
  "titleSep": " "
}'::jsonb) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- RLS 策略：允许 anon 用户读写
-- ============================================
ALTER TABLE ecom_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecom_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE ecom_settings ENABLE ROW LEVEL SECURITY;

-- 允许 anon 读取
CREATE POLICY "Allow anon select on ecom_configs" ON ecom_configs
  FOR SELECT USING (true);

CREATE POLICY "Allow anon select on ecom_products" ON ecom_products
  FOR SELECT USING (true);

CREATE POLICY "Allow anon select on ecom_settings" ON ecom_settings
  FOR SELECT USING (true);

-- 允许 anon 插入/更新/删除
CREATE POLICY "Allow anon insert on ecom_configs" ON ecom_configs
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anon update on ecom_configs" ON ecom_configs
  FOR UPDATE USING (true);

CREATE POLICY "Allow anon delete on ecom_configs" ON ecom_configs
  FOR DELETE USING (true);

CREATE POLICY "Allow anon insert on ecom_products" ON ecom_products
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anon update on ecom_products" ON ecom_products
  FOR UPDATE USING (true);

CREATE POLICY "Allow anon delete on ecom_products" ON ecom_products
  FOR DELETE USING (true);

CREATE POLICY "Allow anon insert on ecom_settings" ON ecom_settings
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anon update on ecom_settings" ON ecom_settings
  FOR UPDATE USING (true);

CREATE POLICY "Allow anon delete on ecom_settings" ON ecom_settings
  FOR DELETE USING (true);

-- ============================================
-- 索引
-- ============================================
CREATE INDEX IF NOT EXISTS idx_ecom_products_platform ON ecom_products(platform);
CREATE INDEX IF NOT EXISTS idx_ecom_products_sort ON ecom_products(sort_order);

-- ============================================
-- 自动更新 updated_at 的函数
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 应用触发器
DROP TRIGGER IF EXISTS update_ecom_configs_updated_at ON ecom_configs;
CREATE TRIGGER update_ecom_configs_updated_at
    BEFORE UPDATE ON ecom_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_ecom_products_updated_at ON ecom_products;
CREATE TRIGGER update_ecom_products_updated_at
    BEFORE UPDATE ON ecom_products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_ecom_settings_updated_at ON ecom_settings;
CREATE TRIGGER update_ecom_settings_updated_at
    BEFORE UPDATE ON ecom_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
