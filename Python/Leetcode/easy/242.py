class Solution:
    def isAnagram(self, s: str, t: str) -> bool:
        from collections import Counter
        s_cnt = Counter(s)
        c_cnt = Counter(t)

        return (s_cnt == c_cnt)