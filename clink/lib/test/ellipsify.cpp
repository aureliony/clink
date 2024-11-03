// Copyright (c) 2024 Christopher Antos
// License: http://opensource.org/licenses/MIT

#include "pch.h"

#include <core/base.h>
#include <core/str.h>
#include <lib/ellipsify.h>

//------------------------------------------------------------------------------
struct testcase
{
    int32 limit;
    const char* in;
    const char* expected;
    ellipsify_mode mode;
    const char* ellipsis;
    bool truncated;
};

//------------------------------------------------------------------------------
TEST_CASE("Ellipsify.")
{
    str<> out;

    static const testcase c_testcases[] =
    {
        { 0,    "",                 "",             RIGHT,  "!" },
        { 1,    "",                 "",             RIGHT,  "!" },
        { 0,    "a",                "",             RIGHT,  "!",    true },
        { 1,    "a",                "a",            RIGHT,  "!" },
        { 1,    "ab",               ".",            RIGHT,  "...",  true },
        { 0,    "abcde",            "",             RIGHT,  "!",    true },
        { 1,    "abcde",            "!",            RIGHT,  "!",    true },
        { 6,    "abcde",            "abcde",        RIGHT,  "!" },
        { 6,    "abcdef",           "abcdef",       RIGHT,  "!" },
        { 6,    "abcdefg",          "abcde!",       RIGHT,  "!",    true },
        { 6,    "abcdefg",          "abc...",       RIGHT,  "...",  true },
        // TODO: escape code tests.

        { 0,    "",                 "",             LEFT,   "!" },
        { 1,    "",                 "",             LEFT,   "!" },
        { 0,    "a",                "",             LEFT,   "!",    true },
        { 1,    "a",                "a",            LEFT,   "!" },
        { 1,    "ab",               ".",            LEFT,   "...",  true },
        { 0,    "abcde",            "",             LEFT,   "!",    true },
        { 1,    "abcde",            "!",            LEFT,   "!",    true },
        { 6,    "abcde",            "abcde",        LEFT,   "!" },
        { 6,    "abcdef",           "abcdef",       LEFT,   "!" },
        { 6,    "abcdefg",          "!cdefg",       LEFT,   "!",    true },
        { 6,    "abcdefg",          "...efg",       LEFT,   "...",  true },
        // TODO: escape code tests.

        { 0,    "c:/abcdef/uvwxyz", "",             PATH,   "!",    true },
        { 1,    "c:/abcdef/uvwxyz", "!",            PATH,   "!",    true },
        { 1,    "c:/abcdef/uvwxyz", ".",            PATH,   "...",  true },
        { 2,    "c:/abcdef/uvwxyz", "c!",           PATH,   "!",    true },
        { 2,    "c:/abcdef/uvwxyz", "..",           PATH,   "...",  true },
        { 3,    "c:/abcdef/uvwxyz", "c:!",          PATH,   "!",    true },
        { 3,    "c:/abcdef/uvwxyz", "...",          PATH,   "...",  true },
        { 4,    "c:/abcdef/uvwxyz", "c:!z",         PATH,   "!",    true },
        { 4,    "c:/abcdef/uvwxyz", "c...",         PATH,   "...",  true },
        { 5,    "c:/abcdef/uvwxyz", "c:!yz",        PATH,   "!",    true },
        { 5,    "c:/abcdef/uvwxyz", "c:...",        PATH,   "...",  true },
        { 6,    "c:/abcdef/uvwxyz", "c:!xyz",       PATH,   "!",    true },
        { 6,    "c:/abcdef/uvwxyz", "c:...z",       PATH,   "...",  true },
        { 10,   "c:/abcdef/uvwxyz", "c:!/uvwxyz",   PATH,   "!",    true },
        { 10,   "c:/abcdef/uvwxyz", "c:...vwxyz",   PATH,   "...",  true },
        // TODO: escape code tests.
    };

    for (auto const& t : c_testcases)
    {
        bool truncated;
        const int32 width = ellipsify_ex(t.in, t.limit, t.mode, out, t.ellipsis, false, &truncated);

        const bool ok = (t.truncated == truncated &&
                            strcmp(t.expected, out.c_str()) == 0);

        REQUIRE(ok, [&] () {
            printf("      in:  \"%s\"\n     out:  \"%s\"%s\nexpected:  \"%s\"%s",
                    t.in,
                    out.c_str(), truncated ? ", truncated" : "",
                    t.expected, t.truncated ? ", truncated" : "");
        });
    }
}
