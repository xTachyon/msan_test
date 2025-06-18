#include <cstdio>
#include <string>

int main() {
    long long x;
    std::string s("abc");
    s += std::to_string(x);
    printf("%s", s.c_str());
}

