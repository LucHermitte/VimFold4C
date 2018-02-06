#include <iostream>
#include <vector>

int main()
{
    std::vector<int> v = {0, 1, 2, 3, 4, 5};
    for (const int& i : v)
    {
        std::cout << i << ' ';
    }

    for (auto c : google::GetLoggingDirectories()) {
        std::clog << c << "\n";
    }
}
