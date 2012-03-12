// EpcDLLTest.c
//
// This console application demonstrates how to initialize
// an EPC10/USB and/or an LIH8+8. Writes the error description
// to standard outpur in case of errors.


#include <stdio.h>
#include <string.h>
#include "EpcDLL.h"


int main( int argc, char* argv[] )
{
	int result;
	unsigned char* error_message[256] = {0};
	unsigned char* path[256] = {0};
	LIH_OptionsType options;

	result = EPC9_DLLVersion();

	memset(	&options, 0, sizeof( options ) );            
 	strcpy_s( (char*) &options.DeviceNumber, sizeof(options.DeviceNumber), "560118080708100" );

//	strcpy( (char*) path, "..\\E9Screen\\" );

	printf( "\nEpcDLL test: \n", result );

	result =
		EPC9_InitializeAndCheckForLife(
			(EPC_Str256Ptr) error_message,
			EPC9_Epc10USBAmpl,
			(EPC_Str256Ptr) path,
            &options,
			sizeof( options ) );

	printf( "result = %d: EPC9_InitializeAndCheckForLife \n", result );

	if (result != EPC9_Success)
		puts( (char*)error_message );

	EPC9_Shutdown();

	result =
		LIH_InitializeInterface(
			(EPC_Str256Ptr) error_message,
			EPC9_Epc7Ampl,
			LIH_LIH88Board,
            &options,
			sizeof( options )  );

	printf( "result = %d: LIH_InitializeInterface \n", result );

	if (result != LIH_Success)
		puts( (char*)error_message );

	LIH_Shutdown();

	return result;
}