#include <cstdio>
#include <string>
#include <set>

int main() {
    std::set<int*> set;
    set.insert(new int(1));

    long long x = 5;
    std::string s("abc");
    s += std::to_string(x);
    printf("%s", s.c_str());
}

