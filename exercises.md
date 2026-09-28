# Phiếu Phản Ánh — K4 Level 3A, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng placeholder trong mỗi câu bằng câu trả lời của bạn.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Nguyễn Như Tài  Mã học viên: 2A202602976

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Khi deploy lên Railway/Render mà quên set `AGENT_API_KEY`, `Settings` ném `ValidationError` ngay lúc process khởi động. Health check không bao giờ xanh, platform báo deploy lỗi trong lúc mình còn đang nhìn log. Nếu khóa mặc định là `"changeme"`, service vẫn lên HTTPS, bot quét được `/ask` và gọi miễn phí bằng khóa đó. Mình chỉ biết khi nhìn chi phí, lúc request đã bị tính tiền.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Dòng log thật:
>
> `{"event": "ask_completed", "level": "info", "timestamp": "2026-09-28T08:02:51.051493+00:00", "user_id": "sv-test", "tokens_in": 12, "tokens_out": 40, "cost_usd": 0.00012}`
>
> Mình lọc được mọi dòng của `user_id` là `sv-test`, và cộng `cost_usd` để ra số tiền user đó đã tiêu. `print("đã trả lời xong")` không có field để lọc và không có số để cộng.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | chưa đo trên máy này |
| Multi-stage | 271MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> `docker images day12-agent:prod` báo **271MB**. Image chạy user `appuser`, base `python:3.11-slim`. Stage builder cài pip vào `/install` rồi bị bỏ; stage runtime chỉ `COPY --from=builder`. Bản 1 stage cũ là `FROM python:3.11` (image đầy đủ, kèm compiler và gói không dùng lúc chạy) rồi `COPY . .` trước khi cài pip, nên kéo theo cả toolchain build. Mình chưa build lại bản 1 stage vì pull `python:3.11` trên mạng này quá chậm; số 271MB là số đo thật của bản multi-stage.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Lần build thứ hai, Docker báo CACHED cho `FROM python:3.11-slim`, `WORKDIR`, `COPY requirements.txt` và `useradd`. Layer `RUN pip install` chạy lại vì mình vừa thêm `--timeout 120` vào đúng dòng đó, và mọi layer sau pip (copy `app`, copy `utils`) cũng chạy lại. Nếu chỉ sửa một ký tự trong `app/main.py`, cache giữ nguyên tới hết `pip install`; chỉ `COPY app` và `COPY utils` phải chạy lại. Đặt `COPY . .` lên trước `pip install` thì sửa một ký tự trong code làm hỏng cache từ chỗ copy source, và pip cài lại toàn bộ thư viện.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Một lỗ hổng trong app Python cho phép kẻ tấn công chạy lệnh trong container. Container mặc định là root, nên lệnh đó chạy với uid 0. Nếu họ thoát khỏi container (escape qua kernel hoặc mount docker socket), uid 0 trong container thành quyền cao trên host. `USER appuser` cắt chuỗi ở bước trong container: process không còn là root, nên cùng lỗ hổng đó cũng chỉ có quyền của user thường. `docker inspect` image `day12-agent:prod` cho `user=appuser`.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Tối đa **20** request trong 2 giây. Gửi 10 request lúc 10:00:59, đúng hạn mức của phút 10:00. Sang 10:01:00 bộ đếm reset về 0, rồi gửi thêm 10 request lúc 10:01:01. Cả 20 request nằm trong khoảng 2 giây mà mỗi phút đồng hồ vẫn chỉ thấy 10. Sliding window 60 giây không có khe đó: 20 request đó cùng nằm trong một cửa sổ.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> Rate limit đếm số request trong 60 giây. Cost guard đếm USD đã tiêu trong tháng. Rate limit cho qua nhưng cost guard phải chặn: user gửi đúng 10 request/phút, mỗi request rất nhiều token, tổng `cost_usd` vượt `MONTHLY_BUDGET_USD` — `/ask` trả 402 trước khi gọi mock LLM. Ngược lại: mỗi request rẻ, ngân sách tháng vẫn còn, nhưng user gửi request thứ 11 trong cùng 60 giây — cost guard cho qua, rate limit trả 429.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Redis mất kết nối. Cả 3 container gọi probe gộp và đều thấy Redis chết nên trả unhealthy. Orchestrator hiểu unhealthy của liveness là "process cần restart", nên restart cả 3 cùng lúc. Trong lúc đó không còn container nào nhận request. Redis sống lại thì cụm vừa bị giết hàng loạt, phải khởi động lại từ đầu. Tách ra thì `/health` vẫn 200 (không restart), `/ready` trả 503 (load balancer chỉ ngừng gửi traffic).

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Gọi `/ask` hai lần cùng `X-User-Id: demo-02` trên image vừa build: lần một `history_length` là 0, lần hai là 2 (một message user và một message assistant của lượt trước). State nằm ở Redis nên container khác cùng Redis vẫn thấy số đó tăng 0, 2, 4. Nếu lịch sử là dict trong RAM, request rơi sang container khác sẽ thấy `history_length` quay về 0 hoặc nhảy lung tung, vì mỗi process một bộ nhớ riêng.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Lần deploy đầu trên Railway, log báo `Application startup failed` và `NotImplementedError: TODO (CP4): cài đặt install`. Traceback chỉ vào `lifecycle.install()` được gọi từ `lifespan` trong `app/main.py`. Nguyên nhân: image đang chạy vẫn là bản starter, hàm `install()` chỉ `raise` chứ chưa đăng ký SIGTERM/SIGINT. Mình sửa `install()` để nhớ handler cũ rồi gắn `request_shutdown`, deploy lại service `day12-agent`. Log sau đó có `Application startup complete` và `Uvicorn running on http://0.0.0.0:8080`. `/health` trả 200, `/ready` trả 200 với `redis: true`.
