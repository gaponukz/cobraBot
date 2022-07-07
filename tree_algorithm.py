def _cucl(index: int) -> int:
    if index % 2 == 0:
        return 0
    
    return index // 2

def winner_generator(index: int) -> int:
    next_index = _cucl(index)

    while (next_index != 0):
        yield next_index
        next_index = _cucl(next_index)

if __name__ == '__main__':
    for index in winner_generator(31):
        print(index)