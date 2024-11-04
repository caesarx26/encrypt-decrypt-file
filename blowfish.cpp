

//  Must ensure g++ compiler is installed:
//	sudo apt-get install g++

// ***************************************************************************

#include <cstdlib>
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <string>
#include <iomanip>

using namespace std;

// ***************************************************************
//  Prototypes for external functions.
//	The "C" specifies to use the standard C/C++ style
//	calling convention.
// these functions are from the assembly file
extern "C" bool getOptions(int, char* [], bool *, FILE **, FILE **);
extern "C" bool readKey(char [], int, int);
extern "C" bool getBlock(FILE *, char [], unsigned int *);
extern "C" bool writeBlock(FILE *, char [], int);

// these functions are from the blowfish library .so file 
extern "C" void generateSubkeys(char []);
extern "C" void blowfishEncrypt(char []);
extern "C" void blowfishDecrypt(char []);

// ***************************************************************
//  Basic C++ program (does not use any objects).

int main(int argc, char* argv[])
{

// --------------------------------------------------------------------
//  Declare variables and simple display header
//	By default, C++ integers are doublewords (32-bits).

	string	bars;
	static const int	KEY_MIN = 16;
	static const int	KEY_MAX = 56;
	FILE		*readFile, *writeFile;
	bool		encryptFlag;
	char		blockArr[9] = {};		// 8 chars and NULL
	char		keyBuff[KEY_MAX+1];		// key and NULL
	unsigned int	blockSize = 0;
	unsigned int	blocksCount = 0;

	bars.append(50,'-');

// --------------------------------------------------------------------
//  If command line arguments OK
//	get key from user
//	generate subkeys (for blowfish initialization)
//	loop to perform encryption/decryption

	if (getOptions(argc, argv, &encryptFlag,
				&readFile, &writeFile)) {

		if (!readKey(keyBuff, KEY_MIN, KEY_MAX)) {
			cout << "Error, no key entered. " <<
				"Program terminated." << endl;
			return 0;
		}

		generateSubkeys(keyBuff);

		// loop to
		//	get 64-bit (8 chars) block from input file
		//	encrypt or decrypt
		//	write result to output file
		while (getBlock(readFile, blockArr, &blockSize)) {

			blocksCount++;

			if (blockSize == 8) {
				if (encryptFlag) {
					blowfishEncrypt(blockArr);
				} else {
					blowfishDecrypt(blockArr);
				}
			}

			if (!writeBlock(writeFile, blockArr, blockSize)) {
				cout << "Error, writing to output file. " <<
					"Program terminated." << endl;
				return 0;
			}
		}

		cout << "Blocks ";
		(encryptFlag) ? cout << "Encypted: " : cout << "Decrypted: ";
		cout << blocksCount << endl;
	}

// --------------------------------------------------------------------
//  Note, file are closed automatically by OS.
//  All done...

	return 0;
}

