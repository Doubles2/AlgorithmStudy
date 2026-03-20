class Solution:
    def isValid(self, s: str) -> bool:
        dict_bracket = {
            ')': '(',
            '}': '{',
            ']': '['
        }
        tmp = []

        for x in s:
            if x in '([{':
                tmp.append(x)
            else:
                if not tmp or tmp[-1] != dict_bracket[x]:
                    return False
                else:
                    tmp.pop()
        
        return len(tmp) == 0