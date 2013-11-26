// g++ -g test_foo.cpp -o test_foo -I ../gtest-1.7.0/include/ ../gtest-1.7.0/lib/.libs/libgtest.a ../gtest-1.7.0/lib/.libs/libgtest_main.a -lpthread
#include "gtest/gtest.h"
#include "foo.h"

TEST(foo, max) {
    EXPECT_EQ(2, max(2, 1));
    EXPECT_EQ(3, max(2, 3));
}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
