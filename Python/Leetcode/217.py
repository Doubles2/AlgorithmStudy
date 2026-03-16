# =====================================
# 리스트 안에서 원소가 2개 이상이면 True, 아니면 False를 반환하는 문제
# 리스트 원소 갯수이면 일단 Counter를 생각하여 문제를 품
# Counter는 values() 자체가 이미 iterable이기에
# return 자체를 간단하게 any(v >= 2 for v in counter_nums.values()) 사용할 수 있음
# =====================================

class Solution:
    def containsDuplicate(self, nums: List[int]) -> bool:
        from collections import Counter
        counter_nums = Counter(nums)
        return any(v >= 2 for v in counter_nums.values())
    
# =========================================
# 1. LeetCode 217. Contains Duplicate 쉽게 푸는 방법
# =========================================
# [문제 핵심]
# - 배열에 같은 값이 2번 이상 나오면 True
# - 모두 1번씩만 나오면 False
#
# [가장 쉬운 풀이]
# - set은 중복을 제거하므로
# - 원래 리스트 길이와 set 길이가 다르면 중복이 있다는 뜻
#
# 예:
# nums = [1, 2, 3, 1]
# len(nums)      = 4
# len(set(nums)) = 3
# -> 중복 존재 -> True
#
# [코드]
# def containsDuplicate(nums):
#     return len(nums) != len(set(nums))
#
# [왜 이게 좋은가]
# - 짧고 직관적임
# - 중복 "존재 여부"만 확인하면 되므로 Counter까지 쓸 필요 없음
#
# [생각 흐름]
# 1) 문제에서 묻는 게 "개수 자체"인지
# 2) 아니면 "중복이 있냐 없냐"만 묻는지 확인
# 3) 중복 유무만 보면 set 먼저 떠올리기
#
# [시간복잡도]
# - set 생성: O(N)
# - 전체: O(N)
#
#
# =========================================
# 2. Counter를 쓰는 문제 유형
# =========================================
# [Counter를 떠올려야 하는 경우]
# - 원소별 등장 횟수(frequency)가 중요할 때
# - 단순 존재 여부가 아니라 "몇 번 나왔는지" 알아야 할 때
#
# [대표 신호]
# 1) 각 원소의 개수를 세어라
# 2) 가장 많이 나온 원소를 구해라
# 3) 두 배열/문자의 구성 개수가 같은지 비교해라
# 4) 정확히 2번, 3번 나온 값을 찾아라
# 5) 빈도 기준으로 정렬/추출해라
#
# [예시 문제 유형]
# - Valid Anagram
#   -> 두 문자열의 문자 개수가 같은지 비교
#
# - Top K Frequent Elements
#   -> 가장 많이 나온 원소 K개 찾기
#
# - 정확히 2번 나온 숫자 찾기
#   -> count == 2 조건 확인
#
# - 과반수 원소/최빈값 느낌 문제
#   -> 어떤 값이 많이 나오는지 확인
#
# [기본 사용법]
# from collections import Counter
#
# nums = [1, 2, 2, 3, 3, 3]
# cnt = Counter(nums)
#
# # 결과
# # Counter({3: 3, 2: 2, 1: 1})
#
# cnt[2]          # 2가 몇 번 나왔는지
# cnt.values()    # 등장 횟수들
# cnt.items()     # (원소, 개수)
#
# [자주 쓰는 패턴]
#
# # 1) 어떤 값이 2번 이상 나오면 True
# any(v >= 2 for v in cnt.values())
#
# # 2) 정확히 2번 나온 값이 있으면 True
# any(v == 2 for v in cnt.values())
#
# # 3) 가장 많이 나온 값 찾기
# max(cnt, key=cnt.get)
#
# # 4) 두 문자열/배열의 구성 비교
# Counter(s) == Counter(t)
#
#
# =========================================
# 3. set / dict / Counter 빠른 구분법
# =========================================
# [set]
# - 중복 제거
# - 중복 존재 여부 확인
# - 방문 여부 체크
#
# [dict]
# - 값 -> 인덱스 저장
# - 값 -> 부가정보 저장
# - 빠른 탐색 + 위치 정보 필요할 때
# - 예: Two Sum
#
# [Counter]
# - 값 -> 등장 횟수 저장
# - 빈도 자체가 중요할 때
#
# [한 줄 요약]
# - 중복 유무만 확인 -> set
# - 값과 위치 저장 -> dict
# - 개수 세기 -> Counter
# =========================================