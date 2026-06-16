-- V22: 方案关联完整模板文件
-- 在 ecom_config_schemes 表中新增两个字段，用于存储模板原始文件和元数据

-- 1. template_rawdata: 存储 Excel 文件的 Base64 编码（支持最大约 10MB 的 Excel 文件）
ALTER TABLE ecom_config_schemes 
ADD COLUMN IF NOT EXISTS template_rawdata TEXT;

-- 2. template_meta: JSONB 格式，存储模板元数据
--    结构: { 
--      "sheetNames": ["Sheet1", "Sheet2", ...],
--      "config": { "sheetName": "Sheet1", "dataStartRow": 6 },
--      "extractSheet": "Sheet1",
--      "extractRow": 1
--    }
ALTER TABLE ecom_config_schemes 
ADD COLUMN IF NOT EXISTS template_meta JSONB;
