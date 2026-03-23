class Solution:
    def isPowerOfTwo(self, n: int) -> bool:
        import math
        if n <= 0:
            return False
        return True if math.log2(n) - int(math.log2(n)) == 0 else False
