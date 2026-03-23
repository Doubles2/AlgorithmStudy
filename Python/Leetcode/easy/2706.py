class Solution:
    def buyChoco(self, prices: List[int], money: int) -> int:
        min_price = 999
        budget = money
        answer = []

        prices.sort()

        for price in prices:
            if price < min_price:
                min_price = price
            else:
                if (price + min_price) <= budget:
                    answer.append(budget - (price + min_price))
        
        return max(answer) if answer else budget
    
# GPT 풀이
# 정렬 후 가장 싼 두 개를 고르면 남는 돈이 최대다.
# 따라서 모든 조합을 볼 필요 없이 prices[0] + prices[1]만 확인하면 된다.
class Solution:
    def buyChoco(self, prices: List[int], money: int) -> int:
        prices.sort()
        total = prices[0] + prices[1]
        return money - total if total <= money else money