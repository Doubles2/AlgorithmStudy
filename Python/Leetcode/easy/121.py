class Solution:
    def maxProfit(self, prices: List[int]) -> int:
        min_price = 999999
        max_profit = 0

        for price in prices:
            if price < min_price:
                min_price = price
            else:
                max_profit = max(max_profit, price - min_price)
        
        return max_profit
    
# [풀이 핵심]
# 모든 날짜 쌍을 비교하면 O(n^2)이라 시간 초과가 난다.
# 이 문제는 "언제 팔까?"를 기준으로 보고,
# 그 전에 나온 가격 중 가장 싼 값에 샀다고 생각하면 된다.

# [아이디어]
# 1. 지금까지의 최소 매수가(min_price)를 저장한다.
# 2. 현재 가격(price)을 오늘 판다고 가정한다.
# 3. 오늘 이익 = price - min_price
# 4. 그 이익의 최댓값을 계속 갱신한다.

# [왜 가능한가]
# 어떤 날에 팔 때 최대 이익을 내려면,
# 그 이전 날짜들 중 가장 낮은 가격에 사는 것이 항상 최선이다.
# 그래서 뒤의 값을 전부 비교할 필요 없이
# 앞에서 본 최소값만 기억하면 된다.

# [시간복잡도]
# O(n) / 한 번만 순회

# [자주 하는 실수]
# - 모든 쌍 비교하기 -> O(n^2)
# - 미래 가격을 최소값에 포함시키기
# - 최소값 갱신 후 이익 계산 순서 헷갈리기