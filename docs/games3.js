/* Batch 2: Hüpfer, Simon, Reaktion, Zahlen, Farben, Balance, Revier, Tap-Sprint, Kopfrechnen, Pfeile, Ausreisser, Grösser */
(()=>{
'use strict';
const {W,H,OR,BL,rnd,text,circle,bg,bear,rrect}=GA,C=()=>GA.c,G=GAMES;
const reg=(id,o)=>{G[id]=Object.assign({name:NAMES[id],sub:'ca. '+SECS[id]+' Sekunden',help:RULES[id],tag:TAGS[id]},o)};
const dist=(a,b,c,d)=>Math.hypot(a-c,b-d);
function hudTime(t,s){text(Math.ceil(Math.max(0,t)),W-34,38,36,BL);if(s!=null)text(s,34,38,36,'#fff')}
const swipeDir=(a,b)=>{const dx=b.x-a.x,dy=b.y-a.y;if(Math.hypot(dx,dy)<34)return null;return Math.abs(dx)>Math.abs(dy)?(dx>0?'r':'l'):(dy>0?'d':'u')};

reg('hopper',{best:'hoch',unit:' m',cpuScore:s=>Math.round(40+s*160*rnd(.6,1.1)),
 init(o,end){const g={x:W/2,y:480,vy:-600,plat:[],h:0,tx:W/2};
  for(let i=0;i<9;i++)g.plat.push({x:rnd(40,W-40),y:600-i*75});g.plat[0].x=W/2;g.plat[0].y=540;
  g.down=g.move=p=>{g.tx=p.x};
  g.update=dt=>{g.x+=(g.tx-g.x)*Math.min(1,dt*10);g.vy+=1300*dt;const py=g.y;g.y+=g.vy*dt;
   if(g.vy>0)g.plat.forEach(p=>{if(py+16<=p.y&&g.y+16>=p.y&&Math.abs(g.x-p.x)<46)g.vy=-720});
   if(g.y<300){const d=300-g.y;g.y=300;g.h+=d;g.plat.forEach(p=>p.y+=d)}
   g.plat=g.plat.filter(p=>p.y<H+20);while(g.plat.length<10){const top=Math.min(...g.plat.map(p=>p.y));g.plat.push({x:rnd(40,W-40),y:top-rnd(62,Math.min(115,70+g.h/40))})}
   if(g.y>H+40)end({score:Math.floor(g.h/10),title:'Abgestürzt',sub:Math.floor(g.h/10)+' m'})};
  g.draw=()=>{const c=C();bg();g.plat.forEach(p=>{c.fillStyle='#7fd8ff';rrect(p.x-38,p.y,76,12,6);c.fill()});bear(g.x,g.y-8,18,OR);text(Math.floor(g.h/10)+' m',W/2,40,36,'#fff')};
  return g}});

reg('simon',{best:'hoch',unit:' Runden',cpuScore:s=>Math.round(2+s*10*rnd(.6,1.1)),
 init(o,end){const cols=['#d9293d','#1fbf5b','#38c8ff','#ffc400'],g={seq:[],show:0,idx:0,state:'pre',t:.8,lit:-1,round:0};
  const add=()=>{g.seq.push(Math.floor(Math.random()*4));g.state='show';g.show=0;g.t=.6;g.idx=0};
  const rect=k=>({x:30+(k%2)*150,y:200+Math.floor(k/2)*150,w:140,h:140});
  g.down=p=>{if(g.state!=='in')return;for(let k=0;k<4;k++){const r=rect(k);if(p.x>r.x&&p.x<r.x+r.w&&p.y>r.y&&p.y<r.y+r.h){g.lit=k;g.lt=.25;if(k===g.seq[g.idx]){g.idx++;if(g.idx>=g.seq.length){g.round=g.seq.length;g.state='pre';g.t=.9}}else end({score:g.round,title:'Falsch!',sub:g.round+' Runden geschafft'})}}};
  g.update=dt=>{g.t-=dt;if(g.lt>0){g.lt-=dt;if(g.lt<=0)g.lit=-1}
   if(g.state==='pre'&&g.t<=0)add();
   else if(g.state==='show'&&g.t<=0){if(g.show<g.seq.length){g.lit=g.seq[g.show];g.lt=.4;g.t=.6;g.show++}else{g.state='in';g.idx=0}}};
  g.draw=()=>{const c=C();bg();for(let k=0;k<4;k++){const r=rect(k);c.globalAlpha=g.lit===k?1:.35;c.fillStyle=cols[k];rrect(r.x,r.y,r.w,r.h,22);c.fill();c.globalAlpha=1}
   text('Runde '+(g.seq.length||1),W/2,90,40,OR);text(g.state==='in'?'Du bist dran':g.state==='show'?'Merken …':'',W/2,150,26,BL)};
  return g}});

reg('reaction',{best:'tief',unit:' ms',cpuScore:s=>Math.round(520-s*300+rnd(-30,30)),
 init(o,end){const g={r:0,s:'wait',t:rnd(1.4,3.6),ms:0,tot:0,msg:'',mt:0,list:[]};
  g.down=()=>{if(g.mt>0)return;if(g.s==='wait'){g.msg='Zu früh!';g.list.push(900);g.mt=1;g.nextWait=true}else{const ms=Math.round(g.ms*1000);g.list.push(ms);g.msg=ms+' ms';g.mt=1}};
  g.update=dt=>{if(g.mt>0){g.mt-=dt;if(g.mt<=0){g.r++;if(g.r>=5){const a=Math.round(g.list.reduce((x,y)=>x+y,0)/5);end({score:a,title:a+' ms',sub:'Durchschnitt über 5 Runden'})}else{g.s='wait';g.t=rnd(1.4,3.6)}}return}
   if(g.s==='wait'){g.t-=dt;if(g.t<=0){g.s='go';g.ms=0}}else g.ms+=dt};
  g.draw=()=>{const c=C();c.fillStyle=g.mt>0?'#243a57':g.s==='go'?'#1fbf5b':'#d9293d';c.fillRect(0,0,W,H);text(g.mt>0?g.msg:g.s==='go'?'JETZT!':'Warten …',W/2,H/2,g.mt>0?44:g.s==='go'?72:48);text('Runde '+(g.r+1)+' / 5',W/2,60,28,'rgba(255,255,255,.85)')};
  return g}});

reg('numbers',{best:'tief',unit:' s',cpuScore:s=>Math.round((28-s*18)*rnd(.9,1.15)*10)/10,
 init(o,end){const g={round:0,t:0,total:0,next:1,pen:0,cells:[],flash:-1};
  const setup=()=>{const n=9+g.round*3,pos=[];for(let i=0;i<n;i++)pos.push(i);pos.sort(()=>Math.random()-.5);g.n=n;g.next=1;g.cols=3;g.rows=n/3;g.cells=pos.map((p,i)=>({v:i+1,p}));};setup();
  const rc=p=>{const cw=(W-40)/g.cols,ch=Math.min(100,(H-220)/g.rows);return{x:20+(p%g.cols)*cw,y:130+Math.floor(p/g.cols)*ch,w:cw-8,h:ch-8}};
  g.down=p=>{for(const k of g.cells){if(k.done)continue;const r=rc(k.p);if(p.x>r.x&&p.x<r.x+r.w&&p.y>r.y&&p.y<r.y+r.h){if(k.v===g.next){k.done=true;g.next++;if(g.next>g.n){g.total+=g.t+g.pen;g.t=0;g.pen=0;g.round++;if(g.round>=3)end({score:Math.round(g.total*10)/10,title:g.total.toFixed(1)+' s',sub:'3 Runden'});else setup()}}else{g.pen+=.5;g.flash=.25}}}};
  g.update=dt=>{g.t+=dt;g.flash-=dt};
  g.draw=()=>{const c=C();bg();g.cells.forEach(k=>{const r=rc(k.p);c.fillStyle=k.done?'#17283d':'#243a57';rrect(r.x,r.y,r.w,r.h,14);c.fill();c.strokeStyle=k.done?'#1c3350':OR;c.lineWidth=2;c.stroke();if(!k.done)text(k.v,r.x+r.w/2,r.y+r.h/2,34,'#fff')});
   text('Runde '+(g.round+1)+' / 3',W/2,40,26,OR);text((g.t+g.pen).toFixed(1)+' s',W/2,84,36,g.flash>0?'#d9293d':'#fff')};
  return g}});

reg('colors',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(6+s*26*rnd(.6,1.1)),
 init(o,end){const nm=['ROT','GRÜN','BLAU','GELB'],cc=['#d9293d','#1fbf5b','#38c8ff','#ffc400'],g={t:30,score:0,w:0,c:0,match:false,fx:0,ok:true};
  const nxt=()=>{g.w=Math.floor(Math.random()*4);g.match=Math.random()<.5;g.c=g.match?g.w:(g.w+1+Math.floor(Math.random()*3))%4};nxt();
  g.down=p=>{if(p.y<400||p.y>560)return;const yes=p.x<W/2;const right=yes===g.match;g.score+=right?1:-1;g.ok=right;g.fx=.25;nxt()};
  g.update=dt=>{g.t-=dt;g.fx-=dt;if(g.t<=0)end({score:g.score,title:'Zeit um!',sub:g.score+' Punkte'})};
  g.draw=()=>{const c=C();bg();text('Passt die Farbe zum Wort?',W/2,110,24,BL);text(nm[g.w],W/2,250,92,cc[g.c]);
   c.fillStyle='#1fbf5b';rrect(20,420,150,120,20);c.fill();c.fillStyle='#d9293d';rrect(190,420,150,120,20);c.fill();text('JA',95,480,44,'#111');text('NEIN',265,480,44,'#111');
   if(g.fx>0)text(g.ok?'+1':'−1',W/2,350,44,g.ok?'#1fbf5b':'#d9293d');hudTime(g.t,g.score)};
  return g}});

reg('balance',{best:'hoch',unit:' s',cpuScore:s=>Math.round((6+s*30*rnd(.6,1.1))*10)/10,
 init(o,end){const g={x:0,v:0,t:0,tilt:0,hold:0,wob:0};
  g.down=g.move=p=>{g.hold=p.x<W/2?-1:1};g.up=()=>{g.hold=0};
  g.update=dt=>{g.t+=dt;g.wob+=dt;const dist=Math.sin(g.wob*1.7)*.35+Math.sin(g.wob*3.1)*.2+(g.x*.7)*(1+g.t/30);g.tilt+=(g.hold*.9-g.tilt)*Math.min(1,dt*5);g.v+=(dist*.6-g.tilt*2.2*(1+g.t/60))*dt;g.v*=1-.4*dt;g.x+=g.v*dt*.8;
   if(Math.abs(g.x)>1)end({score:Math.round(g.t*10)/10,title:'Gekippt!',sub:g.t.toFixed(1)+' Sekunden'});if(g.t>=60)end({score:60,title:'Meister!',sub:'60 Sekunden'})};
  g.draw=()=>{const c=C();bg();c.save();c.translate(W/2,400);c.rotate(g.tilt*.18);c.fillStyle='#7fd8ff';rrect(-150,0,300,16,8);c.fill();circle(g.x*140,-18,18,OR,12);c.restore();
   text(g.t.toFixed(1)+' s',W/2,100,64,'#fff');text('Links / rechts halten zum Kippen',W/2,H-60,20,BL);c.fillStyle='rgba(255,255,255,.06)';c.fillRect(0,0,W/2,H*0);};
  return g}});

reg('territory',{best:'hoch',unit:' Felder',cpuScore:s=>Math.round(20+s*10*rnd(.7,1.1)),
 init(o,end){const cols=6,rows=8,g={t:25,own:new Array(cols*rows).fill(0),cpuT:0};
  const rc=(i)=>{const cw=(W-24)/cols,ch=(H-220)/rows;return{x:12+(i%cols)*cw,y:100+Math.floor(i/cols)*ch,w:cw-4,h:ch-4}};
  g.down=p=>{for(let i=0;i<g.own.length;i++){const r=rc(i);if(p.x>r.x&&p.x<r.x+r.w&&p.y>r.y&&p.y<r.y+r.h)g.own[i]=1}};
  g.update=dt=>{g.t-=dt;g.cpuT+=dt;const rate=1.4+o.skill*6;while(g.cpuT>1/rate){g.cpuT-=1/rate;const a=g.own.map((v,i)=>v!==2?i:-1).filter(i=>i>=0);if(a.length)g.own[a[Math.floor(Math.random()*a.length)]]=2}
   if(g.t<=0){const m=g.own.filter(v=>v===1).length,c=g.own.filter(v=>v===2).length;end({score:m,title:m+' : '+c,sub:'Felder, dein Anteil zuerst'})}};
  g.draw=()=>{const c=C();bg();g.own.forEach((v,i)=>{const r=rc(i);c.fillStyle=v===1?OR:v===2?BL:'#243a57';rrect(r.x,r.y,r.w,r.h,8);c.fill()});
   const m=g.own.filter(v=>v===1).length,k=g.own.filter(v=>v===2).length;text(m,60,50,40,OR);text(k,W-60,50,40,BL);text(Math.ceil(Math.max(0,g.t)),W/2,50,40,'#fff')};
  return g}});

reg('tapsprint',{best:'tief',unit:' s',cpuScore:s=>Math.round((11-s*7+rnd(-.6,.6))*10)/10,
 init(o,end){const g={p:0,t:0,last:0,bear:0};
  g.down=p=>{const side=p.x<W/2?-1:1;if(side!==g.last)g.p+=1.6;else g.p=Math.max(0,g.p-.9);g.last=side;g.bear+=1};
  g.update=dt=>{g.t+=dt;if(g.p>=100)end({score:Math.round(g.t*10)/10,title:g.t.toFixed(1)+' s',sub:'Im Ziel!'});if(g.t>40)end({score:40,title:'Zu langsam',sub:'40 Sekunden'})};
  g.draw=()=>{const c=C();bg();c.fillStyle='rgba(255,106,0,.12)';c.fillRect(0,0,W/2,H);c.fillStyle='rgba(56,200,255,.12)';c.fillRect(W/2,0,W/2,H);
   c.fillStyle='#243a57';rrect(40,120,40,400,20);c.fill();c.fillStyle=OR;const y=520-g.p*4;bear(60,y,22,OR);c.fillStyle='#fff';c.fillRect(32,114,56,6);
   text('Abwechselnd links / rechts tippen',W/2+30,320,15,'#fff');text(g.t.toFixed(1)+' s',W/2+30,80,44,BL);text(Math.round(g.p)+' %',W/2+30,440,56,OR)};
  return g}});

reg('mathduel',{best:'hoch',unit:' Punkte',cpuScore:s=>{let t=0;for(let i=0;i<10;i++)if(Math.random()<.4+s*.5)t+=10+Math.round(rnd(0,5)*(.3+s));return t},
 init(o,end){const g={i:0,score:0,t:0,sel:-1,wait:0,fx:''};
  const mk=()=>{const k=Math.floor(Math.random()*3),a=Math.floor(rnd(2,13+g.i*2)),b=Math.floor(rnd(2,10+g.i));let q,r;if(k===0){q=a+' + '+b;r=a+b}else if(k===1){q=(a+b)+' − '+b;r=a}else{const x=Math.floor(rnd(2,10)),y=Math.floor(rnd(2,10));q=x+' × '+y;r=x*y}
   const set=new Set([r]);while(set.size<3){const d=Math.floor(rnd(1,9))*(Math.random()<.5?-1:1);if(r+d>0)set.add(r+d)}g.q=q;g.r=r;g.opts=[...set].sort(()=>Math.random()-.5);g.t=0;g.sel=-1};mk();
  g.down=p=>{if(g.sel>=0)return;g.opts.forEach((v,k)=>{const y=330+k*84;if(p.x>40&&p.x<W-40&&p.y>y&&p.y<y+68){g.sel=k;if(v===g.r)g.score+=10+Math.max(0,Math.round(5-g.t));g.wait=.7}})};
  g.update=dt=>{if(g.sel>=0){g.wait-=dt;if(g.wait<=0){g.i++;if(g.i>=10)end({score:g.score,title:'Geschafft!',sub:g.score+' Punkte'});else mk()}return}g.t+=dt;if(g.t>8){g.sel=9;g.wait=.6}};
  g.draw=()=>{const c=C();bg();text('Aufgabe '+(g.i+1)+' / 10',W/2,40,26,OR);text(g.q,W/2,200,80,'#fff');
   g.opts.forEach((v,k)=>{const y=330+k*84;c.fillStyle=g.sel>=0?(v===g.r?'#1fbf5b':k===g.sel?'#d9293d':'#243a57'):'#243a57';rrect(40,y,W-80,68,16);c.fill();c.strokeStyle=OR;c.lineWidth=2;c.stroke();text(v,W/2,y+34,36,'#fff')});text(g.score+' Punkte',W/2,H-26,22,BL)};
  return g}});

reg('arrows',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(8+s*28*rnd(.6,1.1)),
 init(o,end){const D=['u','d','l','r'],g={t:30,score:0,d:'u',a:null,fx:0,ok:true};const nx=()=>{g.d=D[Math.floor(Math.random()*4)]};nx();
  g.down=p=>{g.a=p};g.up=p=>{if(!g.a)return;const d=swipeDir(g.a,p);g.a=null;if(!d)return;g.ok=d===g.d;g.score+=g.ok?1:-1;g.fx=.25;nx()};
  g.update=dt=>{g.t-=dt;g.fx-=dt;if(g.t<=0)end({score:g.score,title:'Zeit um!',sub:g.score+' Punkte'})};
  g.draw=()=>{const c=C();bg();const rot={u:0,r:Math.PI/2,d:Math.PI,l:-Math.PI/2}[g.d];c.save();c.translate(W/2,H/2-20);c.rotate(rot);c.fillStyle=OR;c.beginPath();c.moveTo(0,-110);c.lineTo(90,10);c.lineTo(34,10);c.lineTo(34,110);c.lineTo(-34,110);c.lineTo(-34,10);c.lineTo(-90,10);c.closePath();c.fill();c.restore();
   text('Wische in Pfeilrichtung',W/2,H-60,22,BL);if(g.fx>0)text(g.ok?'+1':'−1',W/2,120,44,g.ok?'#1fbf5b':'#d9293d');hudTime(g.t,g.score)};
  return g}});

reg('oddone',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(30+s*50*rnd(.7,1.1)),
 init(o,end){const g={i:0,score:0,t:0,n:3,odd:0,hue:0,fx:0};
  const mk=()=>{g.n=3+Math.min(3,Math.floor(g.i/3));g.odd=Math.floor(Math.random()*g.n*g.n);g.hue=Math.floor(rnd(0,360));g.diff=Math.max(7,22-g.i*1.5);g.t=0};mk();
  const rc=k=>{const s=(W-40)/g.n;return{x:20+(k%g.n)*s,y:140+Math.floor(k/g.n)*s,w:s-8,h:s-8}};
  g.down=p=>{for(let k=0;k<g.n*g.n;k++){const r=rc(k);if(p.x>r.x&&p.x<r.x+r.w&&p.y>r.y&&p.y<r.y+r.h){if(k===g.odd){g.score+=Math.max(1,10-Math.floor(g.t*1.4));g.i++;if(g.i>=10)end({score:g.score,title:'Geschafft!',sub:g.score+' Punkte'});else mk()}else{g.score=Math.max(0,g.score-2);g.fx=.3}}}};
  g.update=dt=>{g.t+=dt;g.fx-=dt};
  g.draw=()=>{const c=C();bg();for(let k=0;k<g.n*g.n;k++){const r=rc(k);c.fillStyle=`hsl(${g.hue},70%,${k===g.odd?50+g.diff:50}%)`;rrect(r.x,r.y,r.w,r.h,12);c.fill()}
   text('Runde '+(g.i+1)+' / 10',W/2,50,28,OR);text(g.score+' Punkte',W/2,100,28,g.fx>0?'#d9293d':'#fff')};
  return g}});

reg('compare',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(8+s*30*rnd(.6,1.1)),
 init(o,end){const g={t:30,score:0,a:0,b:0,lim:2.5,q:0,fx:0,ok:true};
  const nx=()=>{g.a=Math.floor(rnd(10,99));do{g.b=Math.floor(rnd(10,99))}while(g.b===g.a);g.q=0;g.lim=Math.max(1.1,2.6-g.score*.05)};nx();
  g.down=p=>{if(p.y<200||p.y>520)return;const left=p.x<W/2,ok=left===(g.a>g.b);g.ok=ok;g.score+=ok?1:-1;g.fx=.25;nx()};
  g.update=dt=>{g.t-=dt;g.fx-=dt;g.q+=dt;if(g.q>=g.lim){g.score-=1;g.ok=false;g.fx=.25;nx()}if(g.t<=0)end({score:g.score,title:'Zeit um!',sub:g.score+' Punkte'})};
  g.draw=()=>{const c=C();bg();c.fillStyle='#243a57';rrect(20,220,150,260,20);c.fill();rrect(190,220,150,260,20);c.fill();c.strokeStyle=OR;c.lineWidth=2;c.stroke();text(g.a,95,350,64,'#fff');text(g.b,265,350,64,'#fff');
   c.fillStyle=BL;c.fillRect(20,500,320*(1-g.q/g.lim),8);text('Tippe die grössere Zahl',W/2,130,24,BL);if(g.fx>0)text(g.ok?'+1':'−1',W/2,570,44,g.ok?'#1fbf5b':'#d9293d');hudTime(g.t,g.score)};
  return g}});
})();
