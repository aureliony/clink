// Copyright (c) 2023 Christopher Antos
// License: http://opensource.org/licenses/MIT

#pragma once

#include <core/str_iter.h>

//------------------------------------------------------------------------------
typedef int32 wcwidth_t (char32_t);
extern "C" wcwidth_t *wcwidth;
extern void detect_ucs2_limitation(bool force=false);
extern "C" void reset_wcwidths();
extern "C" int32 test_ambiguous_width_char(char32_t ucs, str_iter* iter);
extern "C" void reset_cached_font();
bool is_fully_qualified_double_width_prefix(char32_t ucs);

//------------------------------------------------------------------------------
extern "C" uint32 clink_wcswidth(const char* s, uint32 len);
extern "C" uint32 clink_wcswidth_expandctrl(const char* s, uint32 len);

//------------------------------------------------------------------------------
class wcwidth_iter
{
public:
    explicit        wcwidth_iter(const char* s, int32 len=-1);
    explicit        wcwidth_iter(const str_impl<char>& s, int32 len=-1);
                    wcwidth_iter(const wcwidth_iter& i);
    char32_t        next();
    void            unnext();
    const char*     character_pointer() const { return m_chr_ptr; }
    uint32          character_length() const { return uint32(m_chr_end - m_chr_ptr); }
    int32           character_wcwidth_signed() const { return m_chr_wcwidth; }
    uint32          character_wcwidth_zeroctrl() const { return (m_chr_wcwidth < 0) ? 0 : m_chr_wcwidth; }
    uint32          character_wcwidth_onectrl() const { return (m_chr_wcwidth < 0) ? 1 : m_chr_wcwidth; }
    uint32          character_wcwidth_twoctrl() const { return (m_chr_wcwidth < 0) ? 2 : m_chr_wcwidth; }
    const char*     get_pointer() const;
    void            reset_pointer(const char* s);
    bool            more() const;
    uint32          length() const;

private:
    str_iter        m_iter;
    char32_t        m_next;
    const char*     m_chr_ptr;
    const char*     m_chr_end;
    int32           m_chr_wcwidth = 0;
};
