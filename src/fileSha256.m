function hex=fileSha256(path)
%FILESHA256  SHA-256 of a file as lowercase hex (Java-based, worker safe).
fid=fopen(path,'r'); assert(fid>0,'fileSha256:open','Cannot open %s',path);
bytes=fread(fid,Inf,'*uint8'); fclose(fid);
md=java.security.MessageDigest.getInstance('SHA-256');
digest=md.digest(bytes);
hex=lower(reshape(dec2hex(typecast(digest,'uint8'),2)',1,[]));
end
