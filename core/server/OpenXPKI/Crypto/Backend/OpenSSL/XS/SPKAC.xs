MODULE = OpenXPKI		PACKAGE = OpenXPKI::Crypto::Backend::OpenSSL::SPKAC

OpenXPKI_Crypto_Backend_OpenSSL_SPKAC
_new(sv)
	SV * sv
    PREINIT:
	char * spkac;
	STRLEN len;
    CODE:
	spkac = (char*) SvPV(sv, len);
	RETVAL = NETSCAPE_SPKI_b64_decode(spkac, len);
    OUTPUT:
	RETVAL

SV *
pubkey_algorithm(spkac)
	OpenXPKI_Crypto_Backend_OpenSSL_SPKAC spkac
    PREINIT:
	BIO *out;
        EVP_PKEY *public_key;
	char *pubkey;
//	X509_PUBKEY *xpkey;
//        ASN1_OBJECT *xpoid;
        const EVP_PKEY_ASN1_METHOD *ameth;
        const char *anam = NULL;
	int n;
    CODE:
	out = BIO_new(BIO_s_mem());
#if OPENSSL_VERSION_NUMBER < 0x10100000L
	i2a_ASN1_OBJECT(out, spkac->spkac->pubkey->algor->algorithm);
#else
        public_key = X509_PUBKEY_get(spkac->spkac->pubkey);
        ameth = EVP_PKEY_get0_asn1(public_key);
        if (ameth) {
	  EVP_PKEY_asn1_get0_info(NULL, NULL,
				  NULL, NULL, &anam, ameth);
          BIO_get_mem_data(out, &anam);
	}
#endif
	n = BIO_get_mem_data(out, &pubkey);
	RETVAL = newSVpvn(pubkey, n);
	BIO_free(out);
    OUTPUT:
	RETVAL

SV *
pubkey(spkac)
	OpenXPKI_Crypto_Backend_OpenSSL_SPKAC spkac
    PREINIT:
	BIO *out;
	EVP_PKEY *pkey;
	char *pubkey;
        RSA *rsa = NULL;
        DSA *dsa = NULL;
	int n;
    CODE:
	out = BIO_new(BIO_s_mem());
	pkey=X509_PUBKEY_get(spkac->spkac->pubkey);
	if (pkey != NULL)
	{
#if OPENSSL_VERSION_NUMBER < 0x10100000L
	    if (pkey->type == EVP_PKEY_RSA)
		RSA_print(out,pkey->pkey.rsa,0);
            if (pkey->type == EVP_PKEY_DSA)
		DSA_print(out,pkey->pkey.dsa,0);
#else
            if (EVP_PKEY_id(pkey) == EVP_PKEY_RSA) {
                rsa = EVP_PKEY_get1_RSA(pkey);
		RSA_print(out,rsa,0);
	    }
            if (EVP_PKEY_id(pkey) == EVP_PKEY_DSA) {
	        dsa = EVP_PKEY_get1_DSA(pkey);
		DSA_print(out,dsa,0);
	    }
#endif	    
	    EVP_PKEY_free(pkey);
	}
	n = BIO_get_mem_data(out, &pubkey);
	RETVAL = newSVpvn(pubkey, n);
	BIO_free(out);
    OUTPUT:
	RETVAL

SV *
pubkey_hash (spkac, digest_name="sha1")
	OpenXPKI_Crypto_Backend_OpenSSL_SPKAC spkac
	char *digest_name
    PREINIT:
	EVP_PKEY *pkey;
	BIO *out;
	int j;
	unsigned int n;
	const EVP_MD *digest;
	char * fingerprint;
	unsigned char md[EVP_MAX_MD_SIZE];
	unsigned char *data = NULL;
	int length;
    CODE:
	out = BIO_new(BIO_s_mem());
	pkey=X509_PUBKEY_get(spkac->spkac->pubkey);
	if (pkey != NULL)
	{
		length = i2d_PublicKey (pkey, NULL);
		/* data = OPENSSL_malloc(length+1); */
                /* Do not free this pointer! It is from the EVP_PKEY structure. */
		length = i2d_PublicKey (pkey, &data);
		if (!strcmp ("sha1", digest_name))
			digest = EVP_sha1();
		else
			digest = EVP_md5();

		if (EVP_Digest(data, length, md, &n, digest, NULL))
		{
			BIO_printf(out, "%s:", OBJ_nid2sn(EVP_MD_type(digest)));
			for (j=0; j<(int)n; j++)
			{
				BIO_printf (out, "%02X",md[j]);
				if (j+1 != (int)n) BIO_printf(out,":");
			}
		}
		/* OPENSSL_free (data); */
		EVP_PKEY_free(pkey);
	}
	n = BIO_get_mem_data(out, &fingerprint);
	RETVAL = newSVpvn(fingerprint, n);
	BIO_free(out);
    OUTPUT:
	RETVAL

SV *
keysize (spkac)
	OpenXPKI_Crypto_Backend_OpenSSL_SPKAC spkac
    PREINIT:
	BIO *out;
	EVP_PKEY *pkey;
        RSA *rsa = NULL;
	char * pubkey;
	int n;
    CODE:
	out = BIO_new(BIO_s_mem());
	pkey=X509_PUBKEY_get(spkac->spkac->pubkey);
	if (pkey != NULL)
	{
#if OPENSSL_VERSION_NUMBER < 0x10100000L
		if (pkey->type == EVP_PKEY_RSA)
			BIO_printf(out,"%d", BN_num_bits(pkey->pkey.rsa->n));
#else
		if (EVP_PKEY_id(pkey) == EVP_PKEY_RSA) {
		        rsa = EVP_PKEY_get1_RSA(pkey);
			BIO_printf(out,"%d", RSA_size(rsa));
		}
#endif		
		EVP_PKEY_free(pkey);
	}
	n = BIO_get_mem_data(out, &pubkey);
	RETVAL = newSVpvn(pubkey, n);
	BIO_free(out);
    OUTPUT:
	RETVAL

SV *
modulus (spkac)
	OpenXPKI_Crypto_Backend_OpenSSL_SPKAC spkac
    PREINIT:
	char * modulus;
	BIO *out;
	EVP_PKEY *pkey;
        RSA *rsa = NULL;
        DSA *dsa = NULL;
        const BIGNUM *n_bignum;
	int n;
    CODE:
	out = BIO_new(BIO_s_mem());
	pkey=X509_PUBKEY_get(spkac->spkac->pubkey);
	if (pkey != NULL)
	{
#if OPENSSL_VERSION_NUMBER < 0x10100000L
	    if (pkey->type == EVP_PKEY_RSA)
		BN_print(out,pkey->pkey.rsa->n);
	    if (pkey->type == EVP_PKEY_DSA)
		BN_print(out,pkey->pkey.dsa->pub_key);
#else
	    if (EVP_PKEY_id(pkey) == EVP_PKEY_RSA) {
                rsa = EVP_PKEY_get1_RSA(pkey);
		RSA_get0_key(rsa, &n_bignum, NULL, NULL);
		BN_print(out,n_bignum);
	    }
	    if (EVP_PKEY_id(pkey) == EVP_PKEY_DSA) {
	        dsa = EVP_PKEY_get1_DSA(pkey);
	        DSA_get0_key(dsa, &n_bignum, NULL);
		BN_print(out,n_bignum);
	    }
#endif	    
	    EVP_PKEY_free(pkey);
	}
	n = BIO_get_mem_data(out, &modulus);
	RETVAL = newSVpvn(modulus, n);
	BIO_free(out);
    OUTPUT:
	RETVAL

SV *
exponent (spkac)
	OpenXPKI_Crypto_Backend_OpenSSL_SPKAC spkac
    PREINIT:
	BIO *out;
	EVP_PKEY *pkey;
        RSA *rsa = NULL;
        DSA *dsa = NULL;
        const BIGNUM *e_bignum;
	char *exponent;
	int n;
    CODE:
	out = BIO_new(BIO_s_mem());
	pkey=X509_PUBKEY_get(spkac->spkac->pubkey);
	if (pkey != NULL)
	{
#if OPENSSL_VERSION_NUMBER < 0x10100000L
	    if (pkey->type == EVP_PKEY_RSA)
		BN_print(out,pkey->pkey.rsa->e);
	    if (pkey->type == EVP_PKEY_DSA)
		BN_print(out,pkey->pkey.dsa->pub_key);
#else
	    if (EVP_PKEY_id(pkey) == EVP_PKEY_RSA) {
                rsa = EVP_PKEY_get1_RSA(pkey);
		RSA_get0_key(rsa, NULL, &e_bignum, NULL);
		BN_print(out,e_bignum);
	    }
	    if (EVP_PKEY_id(pkey) == EVP_PKEY_DSA) {
	        dsa = EVP_PKEY_get1_DSA(pkey);
	        DSA_get0_key(dsa, &e_bignum, NULL);
		BN_print(out,e_bignum);
	    }
#endif	    
	    EVP_PKEY_free(pkey);
	}
	n = BIO_get_mem_data(out, &exponent);
	RETVAL = newSVpvn(exponent, n);
	BIO_free(out);
    OUTPUT:
	RETVAL

SV *
signature_algorithm(spkac)
	OpenXPKI_Crypto_Backend_OpenSSL_SPKAC spkac
    PREINIT:
	BIO *out;
	char *sig;
	int n;
    CODE:
	out = BIO_new(BIO_s_mem());
#if OPENSSL_VERSION_NUMBER < 0x10100000L
	i2a_ASN1_OBJECT(out, spkac->sig_algor->algorithm);
#else
#endif
	n = BIO_get_mem_data(out, &sig);
	RETVAL = newSVpvn(sig, n);
	BIO_free(out);
    OUTPUT:
	RETVAL

void
free(spkac)
	OpenXPKI_Crypto_Backend_OpenSSL_SPKAC spkac
    CODE:
        if (spkac != NULL) NETSCAPE_SPKI_free(spkac);

