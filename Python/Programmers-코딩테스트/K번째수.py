def solution(array, commands):
    answer = []
    for lc in commands:
        tmp_list = array[lc[0]-1:lc[1]]
        tmp_list.sort()
        answer.append(tmp_list[lc[2]-1])
    return answer