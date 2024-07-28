local component=component;local computer=computer;computer.setArchitecture("Lua 5.4")local a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C;a=component.proxy(component.list("gpu")())a.bind(component.proxy(component.list("screen")()).address)b,c=a.getResolution()if a.getDepth()>1 then a.setForeground(0x9cc3db)a.setBackground(0x003150)end;d=function(D,E,F,G)if G then return pcall(component.invoke,D,E,F,G)else return pcall(component.invoke,D,E,F)end end;function e(D,H)if H then n,o=d(D,"open",H)else n,o=d(D,"open","/init.lua")end;if n then u=""::I::_,B=d(D,"read",o,math.maxinteger)if B then u=u..B;goto I end;d(D,"close",o)return u else return false end end;function g(J)a.fill(1,1,b,c," ")return a.set(math.ceil(b/2-#J/2),math.ceil(c/2),J)end;function _G.shell()_G.buffer={}_G.print=function(K)for _ in string.gmatch(tostring(K),"[^\r\n]+")do if#tostring(K)>b then for L=1,math.ceil(#tostring(K)/b)do buffer[#buffer+1]=string.sub(tostring(K),L==1 and 1 or b*(L-1),b*L)end else buffer[#buffer+1]=tostring(K)end end end;buffer[1]="bootloader> "v=false;w=false;z=""::M::g("")for L=1,c do if buffer[#buffer-L+1]then a.set(1,c-L+1,buffer[#buffer-L+1])end end;q,_,y,r=computer.pullSignal(1)if not y then if q=="key_down"then if r==42 or r==54 then v=true elseif r==58 then w=not w end elseif q=="key_up"then if r==42 or r==54 then v=false end end else if q=="key_down"then if r==28 then if z=="exit"then return elseif z=="reboot"then computer.shutdown(1)elseif z=="shutdown"then computer.shutdown()end;m,A=pcall(load(z))if A then for _ in string.gmatch(A,"[^\r\n]+")do if#A>b then for L=1,math.ceil(#A/b)do buffer[#buffer+1]=string.sub(A,L==1 and 1 or b*(L-1),b*L)end else buffer[#buffer+1]=A end end end;buffer[#buffer+1]="bootloader> "z=""goto M elseif r==14 then if#buffer[#buffer]>12 then z=string.sub(z,1,#z-1)buffer[#buffer]=string.sub(buffer[#buffer],1,#buffer[#buffer]-1)end;goto M elseif y<127 and y>31 then x=string.char(y)if v or w then x=string.upper(x)end;buffer[#buffer]=buffer[#buffer]..x;z=z..x end end end;goto M end;g("Hold ALT to stay in bootloader")h=component.proxy(component.list("eeprom")())function computer.getBootAddress()return h.getData()end;function computer.setBootAddress(N)return h.setData(N)end::load::i=computer.getBootAddress()j=e(i)if j and component.invoke(i,"getLabel")~="tmpfs"then k=i else for L in pairs(component.list("filesystem"))do j=e(L)k=L;if j and j~=""then computer.setBootAddress(L)goto load;break end end end::O::l=component.invoke(k,"getLabel")m=component.invoke(k,"list","/bios/plugins/")_,C=d(k,"isReadOnly")if m then for _,P in ipairs(m)do if not P:match(".*/$")then o=component.invoke(k,"open","/bios/plugins/"..P)load(component.invoke(k,"read",o,math.huge)or"")()end end else if not C then n=pcall(component.invoke,k,"makeDirectory","/bios/plugins/")if n then goto O end end end;p=computer.uptime()if not j then goto Q end;repeat q,_,_,r=computer.pullSignal(1)if q=="key_down"and r==(56 or 184)then goto Q end until p+1<=computer.uptime()::R::if a.getDepth()>1 then g("Booting to "..(l~=nil and l or"N/A").." ("..k..")")else g("Booting to "..(l~=nil and l or"N/A"))end;load(j)()::Q::f=e(k,"/bios/bl.bin")if f then goto S end;if component.list("filesystem")()then for L in component.list("filesystem")do f=e(L,"/bios/bl.bin")if f then break end end end;if not f then s=component.list("internet")()if s then if component.invoke(s,"isHttpEnabled")then t=component.invoke(s,"request","https://raw.githubusercontent.com/OpenGCX/BlueBIOS/main/binaries/bl.bin")if t then u=""::I::B=t.read()if B then u=u..B;goto I end;if not u==""and u then f=u;if k then if not C then n,o=d(k,"open","/bios/bl.bin","w")if n then d(k,"write",o,f)d(k,"close",o)end end end end end end end end::S::if f and f~=""then load(f)()else g("")shell()end;if j then goto R else computer.shutdown(1)end