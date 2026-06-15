-- =====================================================
-- V49: Supabase Cron 定时清理过期图片
-- 在 Supabase Dashboard → SQL Editor 中执行
--
-- 功能：每小时调用 Edge Function cleanup-expired-images，
--       删除 product-images bucket 中超过 24 小时的图片
--
-- 前提：
--   1. 已部署 Edge Function: supabase functions deploy cleanup-expired-images
--   2. 项目已启用 pg_net 扩展（用于 Cron 调用 HTTP）
-- =====================================================

-- 1. 启用所需扩展
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. 创建定时清理任务：每小时整点执行
-- ⚠️ 执行前请将 <PROJECT_REF> 替换为你的 Supabase 项目 ID
--    在 Dashboard 首页 URL 中可以看到：https://supabase.com/dashboard/project/<PROJECT_REF>
SELECT cron.schedule(
  'cleanup-expired-images-hourly',
  '0 * * * *',
  $$
  SELECT net.http_post(
    url := 'https://<PROJECT_REF>.supabase.co/functions/v1/cleanup-expired-images',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.supabase_service_role_key', true)
    ),
    body := '{}'::jsonb
  );
  $$
);

-- =====================================================
-- 备选方案（推荐）：通过 Dashboard GUI 创建 Cron Job
-- 如果上面的 SQL 报错，请用以下步骤：
--
-- 1. 打开 Supabase Dashboard → Database → Cron
-- 2. 点击 "Create a new cron job"
-- 3. 填写：
--    - Name: cleanup-expired-images-hourly
--    - Schedule: 0 * * * *  (每小时)
--    - Command:
--      SELECT net.http_post(
--        url := 'https://<PROJECT_REF>.supabase.co/functions/v1/cleanup-expired-images',
--        headers := '{"Content-Type":"application/json"}'::jsonb,
--        body := '{}'::jsonb
--      );
-- 4. 保存
--
-- 注意：Cron → Edge Function 不需要 Authorization header，
--       Edge Function 使用内部自动注入的 SUPABASE_SERVICE_ROLE_KEY
-- =====================================================

-- 查看已创建的 Cron 任务
SELECT jobid, schedule, command, active, jobname
FROM cron.job
WHERE jobname = 'cleanup-expired-images-hourly';

-- 查看最近执行记录
SELECT jobid, runid, status, return_message, start_time
FROM cron.job_run_details
WHERE jobid = (
  SELECT jobid FROM cron.job WHERE jobname = 'cleanup-expired-images-hourly'
)
ORDER BY start_time DESC
LIMIT 10;
