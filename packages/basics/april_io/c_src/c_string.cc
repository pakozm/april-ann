/*
 * This file is part of APRIL-ANN toolkit (A
 * Pattern Recognizer In Lua with Artificial Neural Networks).
 *
 * Copyright 2014, Francisco Zamora-Martinez
 *
 * The APRIL-ANN toolkit is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this library; if not, write to the Free Software Foundation,
 * Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 */
#include "april_assert.h"
#include "c_string.h"

namespace april_io {
  CStringStream::CStringStream() :
    StreamMemory(), in_pos(0), out_pos(0) {
    data.reserve(StreamMemory::BLOCK_SIZE);
  }

  CStringStream::CStringStream(const april_utils::string &str) :
    StreamMemory(), data(str), in_pos(0), out_pos(data.size()) {
  }

  CStringStream::CStringStream(const char *str, size_t size) :
    StreamMemory(), data(str, size), in_pos(0), out_pos(size) {
  }
  
  CStringStream::~CStringStream() {
    close();
  }

  april_utils::constString CStringStream::getConstString() const {
    return april_utils::constString(data.c_str(), data.size());
  }

  void CStringStream::swapString(april_utils::string &other) {
    data.swap(other);
  }
  
  char *CStringStream::releaseString() {
    resetBuffers();
    in_pos = out_pos = 0;
    return data.release();
  }
  
  bool CStringStream::empty() const {
    return data.empty();
  }
  
  size_t CStringStream::size() const {
    return data.size();
  }
  
  char CStringStream::operator[](size_t pos) const {
    april_assert(pos < data.size());
    return data[pos];
  }

  char &CStringStream::operator[](size_t pos) {
    april_assert(pos < data.size());
    return data[pos];
  }
  
  void CStringStream::clear() {
    resetBuffers();
    data.clear();
    in_pos = out_pos = 0;
  }
  
  int CStringStream::push(lua_State *L) {
    lua_pushlstring(L, data.c_str(), data.size());
    return 1;
  }
  
  bool CStringStream::isOpened() const {
    return true;
  }
  
  void CStringStream::close() {
    flush();
    // FIXME: closed = true; ???
  }
  
  off_t CStringStream::seek(int whence, int offset) {
    if (whence == SEEK_CUR && offset == 0) return data.size();
    ERROR_EXIT(128, "NOT IMPLEMENTED BEHAVIOR\n");
    return 0;
  }
  
  void CStringStream::flush() {
    size_t new_size = out_pos + getOutBufferPos();
    april_assert(data.capacity() >= new_size);
    if (data.size() < new_size) data.resize(new_size);
  }
  
  int CStringStream::setvbuf(int mode, size_t size) {
    UNUSED_VARIABLE(mode);
    UNUSED_VARIABLE(size);
    return 0;
  }
  
  bool CStringStream::hasError() const {
    return false;
  }
  
  const char *CStringStream::getErrorMsg() const {
    return StreamInterface::NO_ERROR_STRING;
  }
  
  const char *CStringStream::nextInBuffer(size_t &buf_len) {
    april_assert(data.size() >= in_pos + getInBufferPos());
    in_pos += getInBufferPos();
    buf_len = data.size() - in_pos;
    return data.c_str() + in_pos;
  }
  
  char *CStringStream::nextOutBuffer(size_t &buf_len) {
    out_pos += getOutBufferPos();
    if (out_pos >= data.capacity()) {
      data.reserve(data.capacity() << 1);
      in_pos += getInBufferPos();
      resetBuffers();
    }
    buf_len = data.capacity() - out_pos;
    return data.begin() + out_pos;
  }
  
  bool CStringStream::eofStream() const {
    return in_pos >= data.size();
  }
  
  void CStringStream::moveOutBuffer(size_t len) {
    StreamBuffer::moveOutBuffer(len);
    flush();
  }
} // namespace april_io
