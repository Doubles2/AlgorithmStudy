-- 코드를 입력하세요
SELECT
    count(user_id) as users
from
    user_info
where
    1=1
and
    age between '20' and '29'
and
    joined between date('2021-01-01') and date('2021-12-31')