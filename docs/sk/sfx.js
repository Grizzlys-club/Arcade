/* Sfx + Musik: exakt die synthetisierten Klänge der App (Sfx.swift) */
window.Sfx=(()=>{
const RATE=22050;let ctx=null;const bufs={},song={};
const st={enabled:true,music:true};
const AC=()=>{if(!ctx){try{ctx=new (window.AudioContext||window.webkitAudioContext)()}catch(e){}}if(ctx&&ctx.state==='suspended')ctx.resume();return ctx};
const n=(f0,f1,dur,vol,wave)=>({f0,f1,dur,vol:vol==null?.6:vol,wave:wave||0});
const DEF={click:[n(700,900,.05,.4)],tap:[n(880,880,.04,.4)],beep:[n(660,660,.14,.5)],go:[n(990,990,.35,.5,1)],tick:[n(600,600,.03,.3)],jump:[n(300,750,.13,.4)],pop:[n(700,1300,.06,.5)],kick:[n(0,0,.04,.7,2),n(220,80,.12,.8)],hit:[n(0,0,.06,.7,2),n(150,50,.14,.8)],bounce:[n(350,250,.05,.4)],save:[n(0,0,.05,.6,2),n(300,200,.12,.6)],goal:[n(523,523,.09,.5,1),n(659,659,.09,.5,1),n(784,784,.09,.5,1),n(1046,1046,.3,.5,1)],horn:[n(220,220,.5,.5,1),n(330,330,.01,0,0)],miss:[n(400,120,.35,.5)],wrong:[n(160,140,.28,.5,1)],right:[n(660,660,.08,.5),n(990,990,.18,.5)],coin:[n(1200,1500,.07,.4),n(1800,1800,.14,.4)],whistle:[n(2700,2700,.07,.4),n(3000,3000,.07,.4),n(2700,2700,.07,.4),n(3000,3000,.07,.4),n(2700,2700,.1,.4),n(300,300,.01,0)],win:[n(523,523,.11,.5,1),n(523,523,.11,.5,1),n(523,523,.11,.5,1),n(784,784,.4,.5,1)],lose:[n(392,392,.18,.5),n(330,330,.18,.5),n(262,262,.4,.5)],fanfare:[n(523,523,.12,.5,1),n(659,659,.12,.5,1),n(784,784,.12,.5,1),n(1046,1046,.2,.5,1),n(784,784,.1,.5,1),n(1046,1046,.4,.5,1)],stomp:[n(0,0,.05,.5,2),n(90,40,.1,.8)]};
function make(notes){const c=AC();if(!c)return null;let total=0;notes.forEach(o=>total+=Math.max(1,Math.floor(RATE*o.dur)));const b=c.createBuffer(1,total,RATE),d=b.getChannelData(0);let p=0;
 notes.forEach(o=>{const cnt=Math.max(1,Math.floor(RATE*o.dur));let ph=0;for(let i=0;i<cnt;i++){const t=i/cnt,f=o.f0+(o.f1-o.f0)*t;ph+=2*Math.PI*f/RATE;let v=o.wave===1?(Math.sin(ph)>=0?.6:-.6):o.wave===2?Math.random()*2-1:Math.sin(ph);const at=Math.min(1,i/(RATE*.004));let s=v*o.vol*at*Math.pow(1-t,1.4);d[p++]=Math.max(-1,Math.min(1,s))}});return b}

/* Realistischere Klänge: gefiltertes Rauschen, Holz-/Kunststoff-Körper, Hallenhall, Publikum */
const R2=44100;
const REAL=(()=>{
 const rnd=()=>Math.random()*2-1;
 const buf=(sec)=>new Float32Array(Math.floor(R2*sec));
 const env=(i,n,a,d)=>{const t=i/R2;return Math.min(1,t/a)*Math.exp(-t*d)};
 const lp=(x,c)=>{let y=0;for(let i=0;i<x.length;i++){y+=c*(x[i]-y);x[i]=y}return x};
 const hp=(x,c)=>{let y=0;for(let i=0;i<x.length;i++){y+=c*(x[i]-y);x[i]=x[i]-y}return x};
 const add=(d,s,start,gain)=>{const o=Math.floor(start*R2);for(let i=0;i<s.length&&o+i<d.length;i++)d[o+i]+=s[i]*gain};
 const click=(sec,tone,decay)=>{const b=buf(sec);let ph=0;for(let i=0;i<b.length;i++){ph+=2*Math.PI*tone/R2;b[i]=(rnd()*.7+Math.sin(ph)*.5)*env(i,b.length,.0006,decay)}return b};
 const thump=(f0,f1,sec,decay)=>{const b=buf(sec);let ph=0;for(let i=0;i<b.length;i++){const t=i/b.length,f=f0+(f1-f0)*Math.pow(t,.5);ph+=2*Math.PI*f/R2;b[i]=Math.sin(ph)*env(i,b.length,.001,decay)}return b};
 const reverb=(d,wet,t1,t2,t3)=>{const o=new Float32Array(d.length);o.set(d);[[t1,.32],[t2,.22],[t3,.14]].forEach(([tm,g])=>{const k=Math.floor(tm*R2);for(let i=k;i<d.length;i++)o[i]+=o[i-k]*g*wet});return o};
 const norm=(d,peak)=>{let m=.0001;for(let i=0;i<d.length;i++)m=Math.max(m,Math.abs(d[i]));const g=peak/m;for(let i=0;i<d.length;i++)d[i]*=g;return d};
 const noiseBand=(sec,lo,hi,swell,decay)=>{const b=buf(sec);for(let i=0;i<b.length;i++)b[i]=rnd();hp(b,lo);lp(b,hi);for(let i=0;i<b.length;i++){const t=i/b.length;b[i]*=swell?Math.sin(Math.PI*Math.pow(t,.6))*Math.exp(-t*decay):Math.exp(-t*decay)}return b};
 const horn=(sec)=>{const b=buf(sec);let p1=0,p2=0;for(let i=0;i<b.length;i++){p1+=2*Math.PI*233/R2;p2+=2*Math.PI*239/R2;const saw=(Math.sin(p1)+.5*Math.sin(2*p1)+.33*Math.sin(3*p1)+Math.sin(p2)+.5*Math.sin(2*p2))*.3;b[i]=saw*Math.min(1,i/(R2*.03))*Math.min(1,(b.length-i)/(R2*.12))}return b};
 const G={};
 G.hit=()=>{const d=buf(.42);add(d,hp(click(.05,2600,90),.5),0,1);add(d,thump(220,70,.16,22),0,.9);add(d,lp(noiseBand(.12,.3,.25,0,30),.3),0,.35);return norm(reverb(d,.8,.019,.037,.061),.95)};
 G.kick=()=>{const d=buf(.4);add(d,hp(click(.04,1800,110),.4),0,.9);add(d,thump(170,48,.2,16),0,1);return norm(reverb(d,.7,.021,.043,.07),.95)};
 G.bounce=()=>{const d=buf(.3);add(d,thump(420,190,.1,34),0,1);add(d,hp(click(.02,3200,160),.5),0,.4);return norm(reverb(d,.5,.017,.031,.05),.8)};
 G.save=()=>{const d=buf(.35);add(d,lp(noiseBand(.14,.2,.18,0,26),.18),0,1);add(d,thump(150,60,.14,24),0,.8);return norm(reverb(d,.6,.02,.04,.06),.9)};
 G.stomp=()=>{const d=buf(.5);add(d,thump(90,38,.3,9),0,1);add(d,lp(noiseBand(.2,.2,.12,0,16),.1),0,.5);return norm(reverb(d,.9,.03,.06,.1),.95)};
 G.pop=()=>{const d=buf(.18);add(d,thump(800,300,.08,45),0,.8);add(d,hp(click(.012,4000,200),.6),0,.5);return norm(d,.7)};
 G.horn=()=>{const d=buf(1.3);add(d,horn(1.05),0,1);return norm(reverb(d,.9,.05,.11,.2),.9)};
 G.goal=()=>{const d=buf(2.2);add(d,horn(.9),0,.8);add(d,noiseBand(2.0,.01,.12,true,1.1),.1,1.3);for(let k=0;k<6;k++)add(d,noiseBand(.5,.02,.2,true,2),.2+k*.18,.25);return norm(reverb(d,.8,.04,.09,.15),.95)};
 G.win=()=>{const d=buf(2.4);add(d,noiseBand(2.3,.01,.1,true,.9),0,1.2);add(d,horn(.7),.05,.5);return norm(reverb(d,.8,.04,.09,.15),.9)};
 G.fanfare=G.win;
 G.whistle=()=>{const d=buf(.7);let ph=0;for(let i=0;i<d.length;i++){const f=2900+Math.sin(i/R2*38)*140;ph+=2*Math.PI*f/R2;d[i]=(Math.sin(ph)*.6+rnd()*.12)*Math.min(1,i/(R2*.01))*Math.min(1,(d.length-i)/(R2*.08))}return norm(reverb(d,.7,.03,.06,.1),.8)};
 G.miss=()=>{const d=buf(.3);add(d,lp(noiseBand(.25,.15,.06,false,9),.05),0,1);return norm(d,.5)};
 return G})();
function mkReal(name){const c=AC();if(!c||!REAL[name])return null;const f=REAL[name]();const b=c.createBuffer(1,f.length,R2);b.getChannelData(0).set(f);return b}
function play(name){if(!st.enabled)return;const c=AC();if(!c)return;let b=bufs[name];if(!b){if(REAL[name])b=bufs[name]=mkReal(name);else{if(!DEF[name])return;b=bufs[name]=make(DEF[name])}}if(!b)return;const s=c.createBufferSource();s.buffer=b;const g=c.createGain();g.gain.value=.8;s.connect(g);g.connect(c.destination);s.start()}
function makeSong(name){const c=AC();if(!c)return null;const game=name==='game',bpm=game?138:112,beat=60/bpm,bars=8,total=Math.floor(RATE*beat*4*bars),buf=new Float32Array(total);
 const midi=m=>440*Math.pow(2,(m-69)/12);
 const tone=(start,dur,f0,f1,vol,wave,decay)=>{const s0=Math.floor(start*RATE),nn=Math.floor(dur*RATE);let ph=0,seed=((s0&0xffff)+12345)>>>0;for(let i=0;i<nn;i++){const idx=s0+i;if(idx>=total)break;const t=i/nn,f=f0+(f1-f0)*t;ph+=2*Math.PI*f/RATE;let v;switch(wave){case 1:v=Math.sin(ph)>=0?.5:-.5;break;case 2:seed=(Math.imul(seed,1103515245)+12345)>>>0;v=((seed|0)/2147483647);break;case 3:v=2*Math.abs(2*(ph/(2*Math.PI)-Math.floor(ph/(2*Math.PI)+.5)))-1;break;default:v=Math.sin(ph)}const at=Math.min(1,i/(RATE*.005));buf[idx]+=v*vol*at*Math.pow(1-t,decay)}};
 const roots=game?[52,48,55,50]:[57,53,48,55],minor=[true,false,false,false],lead=game?[0,7,12,7,3,7,12,15]:[0,4,7,12,7,4,7,11];
 for(let bar=0;bar<bars;bar++){const cc=Math.floor(bar/2)%4,root=roots[cc],third=minor[cc]?3:4,chord=[0,third,7,12],t0=bar*4*beat;
  for(let b=0;b<4;b++){const bt=t0+b*beat;tone(bt,.16,140,45,.55,0,2.5);tone(bt,beat*.45,midi(root-24),midi(root-24),.28,3,1.2);tone(bt+beat/2,beat*.4,midi(root-12),midi(root-12),.18,3,1.4);tone(bt+beat/2,.04,0,0,.09,2,3);if(game){tone(bt+beat*.25,.03,0,0,.05,2,3);tone(bt+beat*.75,.03,0,0,.05,2,3)}if(b%2===1)tone(bt,.12,0,0,.16,2,2);
   for(let k=0;k<4;k++){const note=root+12+chord[(b*4+k)%4];tone(bt+k*beat/4,beat/4*.9,midi(note),midi(note),.055,1,1.6)}}
  if(bar%2===1)lead.forEach((iv,i)=>{const s=t0+i*beat/2,m=root+12+(minor[cc]?iv:(iv===3?4:(iv===15?16:iv)));tone(s,beat/2*.95,midi(m),midi(m),.07,0,.8)})}
 let peak=.001;for(let i=0;i<total;i++)peak=Math.max(peak,Math.abs(buf[i]));const g=.9/peak;const b=c.createBuffer(1,total,RATE),d=b.getChannelData(0);for(let i=0;i<total;i++)d[i]=Math.max(-1,Math.min(1,buf[i]*g));return b}
let cur=null,src=null,gain=null;
function stopSong(){if(src){try{src.stop()}catch(e){}src=null}}
function music(name){if(name===cur&&src)return;cur=name;stopSong();if(!name||!st.enabled||!st.music)return;const c=AC();if(!c)return;
 setTimeout(()=>{if(cur!==name)return;let b=song[name];if(!b)b=song[name]=makeSong(name);if(!b||cur!==name||!st.enabled||!st.music)return;stopSong();const s=c.createBufferSource();s.buffer=b;s.loop=true;const g=c.createGain();g.gain.value=name==='menu'?.35:.22;s.connect(g);g.connect(c.destination);s.start();src=s},30)}
function set(k,v){st[k]=v;if(!st.enabled||!st.music){stopSong()}else if(cur){const m=cur;cur=null;music(m)}}
return{play,music,set,st,unlock:AC}
})();
window.Haptic=(()=>{const st={enabled:true};const v=n=>{if(st.enabled&&navigator.vibrate)try{navigator.vibrate(n)}catch(e){}};return{st,tap:s=>v(s==='medium'?18:s==='heavy'?28:10),good:()=>v([14,40,14]),bad:()=>v([40,30,40])}})();
