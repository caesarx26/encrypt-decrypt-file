# encrypt-decrypt-file

The program will encrypt or decrypt a file based on what is passed as the command line arguments. The program uses a blowfish algorithm to encrypt/decrypt the data and a buffer to read the files more efficiently. This program will only work in Linux as it uses the Linux standard calling convention.

## Prerequisites

1. **Yasm**: An assembler used for compiling the assembly code.

```bash
   sudo apt-get install yasm
```

2. **Crypto++ Library:** A C++ library that provides cryptographic algorithms and protocols, including Blowfish.

```bash
sudo apt-get install libcrypto++-dev
```

3. Compile The Project

```bash
make
```

- To Cleanup Files

```bash
make clean
```

# Command Line Format To Run Program

./blowfish <-en|-de> -if <inputFileName> -of <outputFileName>

# Example Uses

For example, the encryption program I/O might look like:

---

./blowfish -en -if file.txt -of secret.enc

---

Enter Key: abcdefghijklmnopqrstuvwxyz

For example, the decryption program I/O might look like:

---

./blowfish -de -if secret.enc -of info.txt

---

Enter Key: abcdefghijklmnopqrstuvwxyz

# Key Used to Decrypt Test Files

```
abcdefghijklmnopqrstuvwxyz
```
