#include <cstdio>
#include <iostream>
#include <crypto++/blowfish.h>
#include <crypto++/modes.h>
#include <crypto++/secblock.h>

// External function declarations from the assembly file
extern "C" bool getOptions(int, char *[], bool *, FILE **, FILE **);
extern "C" bool readKey(char[], int, int);
extern "C" bool getBlock(FILE *, char[], unsigned int *);
extern "C" bool writeBlock(FILE *, char[], int);

int main(int argc, char *argv[])
{
	// Declare variables
	static const int KEY_MIN = 16;
	static const int KEY_MAX = 56;
	FILE *readFile, *writeFile;
	bool encryptFlag;
	char blockArr[9] = {};			// 8 chars and NULL
	char keyBuff[KEY_MAX + 1] = {}; // key and NULL
	unsigned int blockSize = 0;
	unsigned int blocksCount = 0;

	if (getOptions(argc, argv, &encryptFlag, &readFile, &writeFile))
	{

		// Read key from user
		if (!readKey(keyBuff, KEY_MIN, KEY_MAX))
		{
			std::cout << "Error, no key entered. Program terminated." << std::endl;
			return 0;
		}

		// Determine actual length of the key
		int keyLength = strnlen(keyBuff, KEY_MAX);

		// Initialize key with the actual length
		CryptoPP::SecByteBlock key(reinterpret_cast<const CryptoPP::byte *>(keyBuff), keyLength);

		// Configure Blowfish in ECB mode: encrypts data in fixed-size blocks independently
		CryptoPP::ECB_Mode<CryptoPP::Blowfish>::Encryption encryptor;
		CryptoPP::ECB_Mode<CryptoPP::Blowfish>::Decryption decryptor;
		encryptor.SetKey(key, key.size());
		decryptor.SetKey(key, key.size());

		// loop to
		//	get 64-bit (8 chars) block from input file
		//	encrypt or decrypt
		//	write result to output file
		while (getBlock(readFile, blockArr, &blockSize))
		{
			blocksCount++;

			if (blockSize == 8)
			{ // Blowfish works with 64-bit (8-byte) blocks
				if (encryptFlag)
				{
					encryptor.ProcessData(reinterpret_cast<CryptoPP::byte *>(blockArr), reinterpret_cast<CryptoPP::byte *>(blockArr), 8);
				}
				else
				{
					decryptor.ProcessData(reinterpret_cast<CryptoPP::byte *>(blockArr), reinterpret_cast<CryptoPP::byte *>(blockArr), 8);
				}
			}

			if (!writeBlock(writeFile, blockArr, blockSize))
			{
				std::cout << "Error, writing to output file. Program terminated." << std::endl;
				return 0;
			}
		}

		std::cout << "Blocks ";
		if (encryptFlag)
		{
			std::cout << "Encrypted: ";
		}
		else
		{
			std::cout << "Decrypted: ";
		}
		std::cout << blocksCount << std::endl;
	}

	return 0;
}
