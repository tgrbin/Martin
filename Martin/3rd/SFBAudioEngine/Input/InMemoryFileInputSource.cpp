/*
 *  Copyright (C) 2010, 2011, 2012, 2013, 2014 Stephen F. Booth <me@sbooth.org>
 *  All Rights Reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 *
 *    - Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *    - Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *    - Neither the name of Stephen F. Booth nor the names of its 
 *      contributors may be used to endorse or promote products derived
 *      from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <cstdio>

#include "InMemoryFileInputSource.h"

#pragma mark Creation and Destruction

SFB::InMemoryFileInputSource::InMemoryFileInputSource(CFURLRef url)
	: InputSource(url), mMemory(nullptr), mCurrentPosition(nullptr)
{
	memset(&mFilestats, 0, sizeof(mFilestats));
}

bool SFB::InMemoryFileInputSource::_Open(CFErrorRef *error)
{
	using unique_FILE_ptr = std::unique_ptr<std::FILE, std::function<int(std::FILE *)>>;

	UInt8 buf [PATH_MAX];
	Boolean success = CFURLGetFileSystemRepresentation(GetURL(), FALSE, buf, PATH_MAX);
	if(!success) {
		if(error)
			*error = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainPOSIX, EIO, nullptr);
		return false;
	}

	auto file = unique_FILE_ptr(std::fopen((const char *)buf, "r"), std::fclose);
	if(!file) {
		if(error)
			*error = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainPOSIX, errno, nullptr);
		return false;
	}

	if(-1 == fstat(::fileno(file.get()), &mFilestats)) {
		if(error)
			*error = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainPOSIX, errno, nullptr);
		return false;
	}

	// Perform the allocation
	mMemory = std::unique_ptr<int8_t []>(new int8_t [mFilestats.st_size]);
	if(!mMemory) {
		if(error)
			*error = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainPOSIX, errno, nullptr);
		return false;
	}

	// Read the file
	if((size_t)mFilestats.st_size != ::fread(mMemory.get(), 1, (size_t)mFilestats.st_size, file.get())) {
		if(error)
			*error = CFErrorCreate(kCFAllocatorDefault, kCFErrorDomainPOSIX, errno, nullptr);

		return false;
	}

	mCurrentPosition = mMemory.get();

	return true;
}

bool SFB::InMemoryFileInputSource::_Close(CFErrorRef */*error*/)
{
	memset(&mFilestats, 0, sizeof(mFilestats));
	mMemory.reset();
	mCurrentPosition = nullptr;

	return true;
}

SInt64 SFB::InMemoryFileInputSource::_Read(void *buffer, SInt64 byteCount)
{
	ptrdiff_t remaining = (mMemory.get() + mFilestats.st_size) - mCurrentPosition;

	if(byteCount > remaining)
		byteCount = remaining;

	memcpy(buffer, mCurrentPosition, (size_t)byteCount);
	mCurrentPosition += byteCount;
	return byteCount;
}

bool SFB::InMemoryFileInputSource::_SeekToOffset(SInt64 offset)
{
	if(offset > mFilestats.st_size)
		return false;
	
	mCurrentPosition = mMemory.get() + offset;
	return true;
}
