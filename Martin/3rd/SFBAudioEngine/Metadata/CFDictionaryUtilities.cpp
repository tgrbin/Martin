/*
 *  Copyright (C) 2012, 2013, 2014 Stephen F. Booth <me@sbooth.org>
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

#include "CFDictionaryUtilities.h"
#include "CFWrapper.h"

void SFB::AddIntToDictionary(CFMutableDictionaryRef d, CFStringRef key, int value)
{
	if(nullptr == d || nullptr == key)
		return;
	
	SFB::CFNumber num = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &value);
	if(num)
		CFDictionarySetValue(d, key, num);
}

void SFB::AddIntToDictionaryAsString(CFMutableDictionaryRef d, CFStringRef key, int value)
{
	if(nullptr == d || nullptr == key)
		return;

	SFB::CFString str = CFStringCreateWithFormat(kCFAllocatorDefault, nullptr, CFSTR("%d"), value);
	if(str)
		CFDictionarySetValue(d, key, str);
}

void SFB::AddLongLongToDictionary(CFMutableDictionaryRef d, CFStringRef key, long long value)
{
	if(nullptr == d || nullptr == key)
		return;

	SFB::CFNumber num = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &value);
	if(num)
		CFDictionarySetValue(d, key, num);
}

void SFB::AddFloatToDictionary(CFMutableDictionaryRef d, CFStringRef key, float value)
{
	if(nullptr == d || nullptr == key)
		return;

	SFB::CFNumber num = CFNumberCreate(kCFAllocatorDefault, kCFNumberFloatType, &value);
	if(num)
		CFDictionarySetValue(d, key, num);
}

void SFB::AddDoubleToDictionary(CFMutableDictionaryRef d, CFStringRef key, double value)
{
	if(nullptr == d || nullptr == key)
		return;
	
	SFB::CFNumber num = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &value);
	if(num)
		CFDictionarySetValue(d, key, num);
}
