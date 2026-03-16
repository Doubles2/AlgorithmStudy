# ==============================
# 내가 생각한 방법: 정렬이나 트리 구조가 아닌 최적화 구현일 것 같다는 생각 -> 브루트포스
# 그런, -10^9 ~ 10^9 이기에 2중 for 문을 하는 건 문제가 있다고 판단함
# 그래서 
# for idx, x in enumerate(nums):
#    if target - x in nums
# 위와 같은 구조로 효율적으로 탐색할 수 있는 방법을 찾음
# ==============================

class Solution:
    def twoSum(self, nums: List[int], target: int) -> List[int]:
        hashdict = {}

        for idx, x in enumerate(nums):
            diff = target - x

            if diff in hashdict:
                return([hashdict[diff], idx])
            
            hashdict[x] = idx


# 😎 GPT 추가 풀이 정리: [해시 / Two Sum류 문제 접근법]
# 1. 먼저 브루트포스(이중 for문)로 풀 수 있는지 생각한다.
#    - 모든 쌍을 비교하면 직관적이지만 보통 O(N^2)라 비효율적이다.
#
# 2. 문제의 핵심이 "특정 값이 있는지 빠르게 찾는 것"인지 확인한다.
#    - 예: 현재 값 x에 대해 target - x 가 존재하는지 확인
#
# 3. 리스트에서 in 으로 찾으면 O(N)이므로,
#    반복문 안에서 사용하면 전체가 다시 O(N^2)가 된다.
#
# 4. 빠른 탐색이 필요하면 dict(해시)를 사용한다.
#    - key: 값
#    - value: 해당 값의 인덱스 또는 부가 정보
#
# 5. 순회하면서
#    - 먼저 필요한 값(target - x)이 이미 dict에 있는지 확인하고
#    - 없으면 현재 값을 dict에 저장한다.
#
# 6. 이런 유형의 신호
#    - 두 수의 합 / 차 / 보완값(complement)
#    - 중복 확인
#    - "존재 여부를 빠르게 찾기"
#    - 인덱스나 원래 위치를 함께 저장해야 함
#
# 7. 자주 나오는 패턴
#    for idx, x in enumerate(nums):
#        diff = target - x
#        if diff in hashmap:
#            return [hashmap[diff], idx]
#        hashmap[x] = idx