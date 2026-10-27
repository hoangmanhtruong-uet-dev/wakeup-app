-- ==============================================================================
-- SUPABASE RPC: XÓA TÀI KHOẢN NGƯỜI DÙNG (ACCOUNT DELETION)
-- Hướng dẫn: Mở Supabase Dashboard -> SQL Editor -> Dán đoạn mã này -> Run
-- ==============================================================================

-- 1. Tạo function xóa tài khoản của chính user đang gọi (auth.uid())
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user_id uuid;
BEGIN
  -- Lấy user_id từ JWT token của người dùng hiện tại
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RAISE EXCEPTION 'Bạn chưa đăng nhập hoặc phiên làm việc đã hết hạn.';
  END IF;

  -- 1. Xóa các dữ liệu liên quan trong schema public nếu có (ví dụ: profiles, user_settings...)
  -- DELETE FROM public.profiles WHERE id = current_user_id;

  -- 2. Xóa tài khoản người dùng trực tiếp trong auth.users
  -- Vì hàm này được khai báo SECURITY DEFINER, nó có toàn quyền xóa bản ghi auth.
  DELETE FROM auth.users WHERE id = current_user_id;
END;
$$;

-- 2. Cấp quyền thực thi hàm cho authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
