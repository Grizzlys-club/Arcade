(()=>{
'use strict';
const W=360,H=640,cv=document.getElementById('cv'),c=cv.getContext('2d'),ov=document.getElementById('ov');
const OR='#FF6A00',BL='#38c8ff',BG='#0d1a2b';
let cur=null,gameId=null,last=0,raf=0,over=false;
const store={get(k){try{return localStorage.getItem('ga.'+k)}catch(e){return null}},set(k,v){try{localStorage.setItem('ga.'+k,v)}catch(e){}}};
const rnd=(a,b)=>a+Math.random()*(b-a);
function pos(e){const r=cv.getBoundingClientRect();return{x:(e.clientX-r.left)*W/r.width,y:(e.clientY-r.top)*H/r.height}}
function text(t,x,y,s,col,al){c.font=`900 ${s}px Archivo, Impact, sans-serif`;c.fillStyle=col||'#fff';c.textAlign=al||'center';c.textBaseline='middle';c.fillText(t,x,y)}
function circle(x,y,r,col,glow){c.save();if(glow){c.shadowColor=col;c.shadowBlur=glow}c.fillStyle=col;c.beginPath();c.arc(x,y,r,0,7);c.fill();c.restore()}
function bg(){c.fillStyle=BG;c.fillRect(0,0,W,H)}
function bear(x,y,s,col){circle(x,y,s,col||OR);circle(x-s*.62,y-s*.78,s*.32,col||OR);circle(x+s*.62,y-s*.78,s*.32,col||OR);circle(x-s*.3,y-s*.1,s*.11,'#111');circle(x+s*.3,y-s*.1,s*.11,'#111');circle(x,y+s*.28,s*.3,'#ffd9b0');circle(x,y+s*.2,s*.1,'#111')}

/* ---------- Spiele ---------- */
const G={};

G.airhockey={name:'Air-Hockey',sub:'Gegen den Computer, bis 5',img:'airhockey',help:'Zieh deinen Schläger unten mit dem Finger oder der Maus.',
 init(){const g={sc:[0,0],p:{x:W/2,y:H/2,vx:0,vy:0,r:15},me:{x:W/2,y:H-90,r:28,vx:0,vy:0},cpu:{x:W/2,y:90,r:28,vx:0,vy:0},tx:W/2,ty:H-90,wait:.8,trail:[]};
  g.serve=d=>{g.p.x=W/2;g.p.y=H/2;g.p.vx=0;g.p.vy=0;g.wait=.9;g.dir=d};
  g.serve(1);
  g.move=p=>{g.tx=p.x;g.ty=p.y};g.down=g.move;
  const hit=(p,pd)=>{const dx=p.x-pd.x,dy=p.y-pd.y,d=Math.hypot(dx,dy),m=p.r+pd.r;if(d<m&&d>0){const nx=dx/d,ny=dy/d;p.x=pd.x+nx*m;p.y=pd.y+ny*m;const rel=(p.vx-pd.vx)*nx+(p.vy-pd.vy)*ny;if(rel<0){p.vx-=2*rel*nx;p.vy-=2*rel*ny}const s=Math.hypot(p.vx,p.vy);if(s>560){p.vx*=560/s;p.vy*=560/s}if(s<90&&s>0){p.vx*=1.4;p.vy*=1.4}}};
  g.update=dt=>{
   const m=g.me,pk=g.p,cp=g.cpu;
   let nx=Math.max(m.r,Math.min(W-m.r,g.tx)),ny=Math.max(H/2+m.r,Math.min(H-m.r,g.ty));
   m.vx=(nx-m.x)/dt;m.vy=(ny-m.y)/dt;m.x=nx;m.y=ny;
   // CPU
   let tx=W/2,ty=70;
   if(pk.y<H/2+20){tx=pk.x;ty=pk.y<cp.y+40?Math.max(55,pk.y-45):Math.min(H/2-40,pk.y-34);if(pk.vy<-80&&pk.y<H/2){ty=70}}
   const sp=210,ox=cp.x,oy=cp.y,dxx=tx-cp.x,dyy=ty-cp.y,dd=Math.hypot(dxx,dyy)||1,stp=Math.min(dd,sp*dt);
   cp.x+=dxx/dd*stp;cp.y+=dyy/dd*stp;cp.x=Math.max(cp.r,Math.min(W-cp.r,cp.x));cp.y=Math.max(cp.r,Math.min(H/2-cp.r,cp.y));
   cp.vx=(cp.x-ox)/dt;cp.vy=(cp.y-oy)/dt;
   if(g.wait>0){g.wait-=dt;return}
   if(!pk.vx&&!pk.vy&&g.dir){pk.vy=g.dir*160;pk.vx=rnd(-60,60);g.dir=0}
   pk.x+=pk.vx*dt;pk.y+=pk.vy*dt;pk.vx*=.9985;pk.vy*=.9985;
   if(pk.x<pk.r){pk.x=pk.r;pk.vx=Math.abs(pk.vx)}if(pk.x>W-pk.r){pk.x=W-pk.r;pk.vx=-Math.abs(pk.vx)}
   const gl=W/2-62,gr=W/2+62,inG=pk.x>gl&&pk.x<gr;
   if(pk.y<pk.r&&!inG){pk.y=pk.r;pk.vy=Math.abs(pk.vy)}
   if(pk.y>H-pk.r&&!inG){pk.y=H-pk.r;pk.vy=-Math.abs(pk.vy)}
   hit(pk,m);hit(pk,cp);
   g.trail.push([pk.x,pk.y]);if(g.trail.length>9)g.trail.shift();
   if(pk.y<-pk.r){g.sc[0]++;g.flash=1;g.serve(-1)}
   if(pk.y>H+pk.r){g.sc[1]++;g.flash=-1;g.serve(1)}
   if(g.sc[0]>=5)end('Gewonnen!',g.sc[0]+' : '+g.sc[1],null);
   if(g.sc[1]>=5)end('Knapp verloren',g.sc[0]+' : '+g.sc[1],null);
  };
  g.draw=()=>{bg();c.strokeStyle='rgba(56,200,255,.55)';c.lineWidth=3;c.strokeRect(2,2,W-4,H-4);
   c.beginPath();c.moveTo(0,H/2);c.lineTo(W,H/2);c.stroke();c.beginPath();c.arc(W/2,H/2,52,0,7);c.stroke();
   c.fillStyle=OR;c.fillRect(W/2-62,H-6,124,6);c.fillStyle=BL;c.fillRect(W/2-62,0,124,6);
   g.trail.forEach((t,i)=>circle(t[0],t[1],g.p.r*(i/9),'rgba(255,255,255,'+(i/20)+')'));
   circle(g.p.x,g.p.y,g.p.r,'#fff',14);circle(g.cpu.x,g.cpu.y,g.cpu.r,BL,18);circle(g.me.x,g.me.y,g.me.r,OR,18);
   circle(g.cpu.x,g.cpu.y,g.cpu.r*.45,'rgba(0,0,0,.25)');circle(g.me.x,g.me.y,g.me.r*.45,'rgba(0,0,0,.25)');
   text(g.sc[1],28,H/2-24,40,'rgba(255,255,255,.5)');text(g.sc[0],28,H/2+24,40,OR)};
  return g}};

G.flappy={name:'Flatter-Bär',sub:'Tippen zum Flattern',img:'flappy',help:'Tippe oder klicke, damit der Bär steigt. Weiche den Eisblöcken aus.',best:'hoch',
 init(){const g={y:H/2,vy:0,pipes:[],t:0,score:0,sp:130,started:false};
  g.flap=()=>{g.started=true;g.vy=-300};g.down=g.flap;
  g.update=dt=>{if(!g.started)return;g.vy+=950*dt;g.y+=g.vy*dt;g.t+=dt;
   if(g.t>1.45){g.t=0;g.pipes.push({x:W+30,gap:rnd(190,H-230),done:false})}
   g.pipes.forEach(p=>{p.x-=g.sp*dt;if(!p.done&&p.x<W/2-20){p.done=true;g.score++}
    if(Math.abs(p.x-W/2)<48&&(g.y<p.gap-70+16||g.y>p.gap+70-16)){end('Aua!',g.score+' Punkte','flappy',g.score)}});
   g.pipes=g.pipes.filter(p=>p.x>-60);
   if(g.y<0||g.y>H)end('Aua!',g.score+' Punkte','flappy',g.score)};
  g.draw=()=>{bg();c.fillStyle='rgba(56,200,255,.08)';for(let i=0;i<9;i++)c.fillRect(0,i*80,W,2);
   g.pipes.forEach(p=>{c.fillStyle='#7fd8ff';c.fillRect(p.x-30,0,60,p.gap-70);c.fillRect(p.x-30,p.gap+70,60,H);c.fillStyle='#fff';c.fillRect(p.x-34,p.gap-86,68,16);c.fillRect(p.x-34,p.gap+70,68,16)});
   c.save();c.translate(W/2,g.y);c.rotate(Math.max(-.5,Math.min(.9,g.vy/500)));bear(0,0,22);c.restore();
   text(g.score,W/2,70,64,'#fff');if(!g.started)text('Tippen',W/2,H-110,30,OR)};
  return g}};

G.reflex={name:'Finger-Blitz',sub:'Wie schnell bist du?',img:'reflex',help:'Warte, bis es grün wird. Dann tippe so schnell du kannst.',best:'tief',
 init(){const g={s:'wait',t:rnd(1.5,3.8),r:0};
  g.down=()=>{if(g.s==='wait'){end('Zu früh!','Warte auf Grün','reflex')}else if(g.s==='go'){const ms=Math.round(g.r*1000);end(ms+' ms',ms<250?'Blitzschnell':ms<350?'Gut':'Geht schneller','reflex',ms)}};
  g.update=dt=>{if(g.s==='wait'){g.t-=dt;if(g.t<=0){g.s='go';g.r=0}}else g.r+=dt};
  g.draw=()=>{c.fillStyle=g.s==='go'?'#1fbf5b':'#d9293d';c.fillRect(0,0,W,H);
   text(g.s==='go'?'JETZT!':'Warten …',W/2,H/2-10,g.s==='go'?72:48);if(g.s==='go')text(Math.round(g.r*1000)+' ms',W/2,H/2+60,28,'rgba(255,255,255,.85)')};
  return g}};

G.stoptime={name:'Zeit-Stopp',sub:'Genau 5 Sekunden',img:'stoptime',help:'Die Zeit läuft und verschwindet nach 2 Sekunden. Stoppe bei genau 5,00.',best:'tief',
 init(){const g={t:0,run:false};
  g.down=()=>{if(!g.run){g.run=true;return}const d=Math.abs(g.t-5);end(g.t.toFixed(2)+' s',d<.05?'Fast perfekt':'Daneben um '+d.toFixed(2)+' s','stoptime',+d.toFixed(2))};
  g.update=dt=>{if(g.run)g.t+=dt};
  g.draw=()=>{bg();text('Ziel 5,00',W/2,150,34,OR);
   const show=!g.run||g.t<2;text(g.run?(show?g.t.toFixed(2):'?.??'):'0.00',W/2,H/2,92,'#fff');
   text(g.run?'Tippen zum Stoppen':'Tippen zum Starten',W/2,H-130,26,BL)};
  return g}};

G.whack={name:'Puck-Jagd',sub:'30 Sekunden',img:'whack',help:'Tippe die Pucks, bevor sie verschwinden. Orange zählt, rot kostet Punkte.',best:'hoch',
 init(){const g={t:30,score:0,items:[],sp:0,fx:[]};
  g.down=p=>{for(let i=g.items.length-1;i>=0;i--){const it=g.items[i];if(Math.hypot(p.x-it.x,p.y-it.y)<it.r+8){g.score+=it.bad?-2:1;g.fx.push({x:it.x,y:it.y,t:.4,bad:it.bad});g.items.splice(i,1);return}}};
  g.update=dt=>{g.t-=dt;g.sp-=dt;if(g.sp<=0){g.sp=rnd(.35,.7);g.items.push({x:rnd(40,W-40),y:rnd(110,H-60),r:26,life:1.1,max:1.1,bad:Math.random()<.2})}
   g.items.forEach(i=>i.life-=dt);g.items=g.items.filter(i=>i.life>0);g.fx.forEach(f=>f.t-=dt);g.fx=g.fx.filter(f=>f.t>0);
   if(g.t<=0)end('Zeit um!',g.score+' Punkte','whack',g.score)};
  g.draw=()=>{bg();g.items.forEach(i=>{const k=i.life/i.max;circle(i.x,i.y,i.r*(.5+.5*k),i.bad?'#d9293d':OR,16);circle(i.x,i.y,i.r*.35*(.5+.5*k),'rgba(0,0,0,.35)')});
   g.fx.forEach(f=>{c.globalAlpha=f.t/.4;circle(f.x,f.y,50*(1-f.t/.4)+20,f.bad?'#d9293d':'#fff');c.globalAlpha=1});
   text(Math.ceil(Math.max(0,g.t)),W-40,44,40,BL,'center');text(g.score,40,44,40,'#fff','center')};
  return g}};

G.memory={name:'Bären-Memory',sub:'Paare finden',img:'memory',help:'Finde alle Paare mit möglichst wenig Zügen.',best:'tief',
 init(){const sy=['🐻','🏒','🥅','🧊','🔥','⭐','🏆','⚡'];let a=[...sy,...sy].sort(()=>Math.random()-.5);
  const g={cards:a.map((s,i)=>({s,i,up:false,ok:false})),open:[],moves:0,lock:0};
  const cw=74,ch=92,gx=(W-4*cw)/5,gy=(H-130-4*ch)/5;
  const pr=i=>({x:gx+(i%4)*(cw+gx),y:110+gy+Math.floor(i/4)*(ch+gy)});
  g.down=p=>{if(g.lock>0)return;for(const k of g.cards){const q=pr(k.i);if(!k.up&&!k.ok&&p.x>q.x&&p.x<q.x+cw&&p.y>q.y&&p.y<q.y+ch){k.up=true;g.open.push(k);if(g.open.length===2){g.moves++;if(g.open[0].s===g.open[1].s){g.open.forEach(o=>o.ok=true);g.open=[];if(g.cards.every(o=>o.ok))end('Alle Paare!',g.moves+' Züge','memory',g.moves)}else g.lock=.8}return}}};
  g.update=dt=>{if(g.lock>0){g.lock-=dt;if(g.lock<=0){g.open.forEach(o=>o.up=false);g.open=[]}}};
  g.draw=()=>{bg();text('Züge '+g.moves,W/2,56,34,OR);g.cards.forEach(k=>{const q=pr(k.i);c.fillStyle=k.up||k.ok?'#fff':'#243a57';c.strokeStyle=k.ok?'#1fbf5b':OR;c.lineWidth=2;c.beginPath();c.roundRect(q.x,q.y,cw,ch,12);c.fill();c.stroke();
   if(k.up||k.ok){c.font='38px system-ui';c.textAlign='center';c.textBaseline='middle';c.fillStyle='#000';c.fillText(k.s,q.x+cw/2,q.y+ch/2+2)}else text('G',q.x+cw/2,q.y+ch/2,34,OR)})};
  return g}};

G.tugwar={name:'Tauziehen',sub:'Allein oder zu zweit',img:'tugwar',help:'Tippe so schnell du kannst auf deine Hälfte unten. Zu zweit tippt der andere oben.',
 init(){const g={pos:0,human2:false,cpuT:0,cpuRate:5.2,taps:[0,0],age:0};
  g.down=p=>{if(p.y>H/2){g.pos-=.017}else{g.human2=true;g.pos+=.017}};
  g.update=dt=>{g.age+=dt;if(!g.human2){g.cpuT+=dt;const iv=1/g.cpuRate;while(g.cpuT>iv){g.cpuT-=iv;g.pos+=.0155}}
   g.pos*=1-.15*dt;
   if(g.pos<-1)end('Gewonnen!',g.human2?'Unten gewinnt':'Du hast den Computer gezogen',null);
   if(g.pos>1)end(g.human2?'Oben gewinnt':'Computer gewinnt',g.human2?'':'Nächstes Mal schneller tippen',null)};
  g.draw=()=>{bg();c.fillStyle='rgba(255,106,0,.18)';c.fillRect(0,H/2,W,H/2);c.fillStyle='rgba(56,200,255,.16)';c.fillRect(0,0,W,H/2);
   const y=H/2+g.pos*(H/2-70);c.fillStyle='#fff';c.fillRect(W/2-4,0,8,H);c.fillStyle=OR;c.fillRect(0,y-3,W,6);
   bear(W/2,y,34,OR);text('TIPPEN',W/2,H-60,36,'rgba(255,255,255,.35)');
   c.save();c.translate(W/2,60);c.rotate(Math.PI);text(g.human2?'TIPPEN':'CPU',0,0,36,'rgba(255,255,255,.35)');c.restore()};
  return g}};

/* ---------- Rahmen ---------- */
function end(title,sub,key,score){if(over)return;over=true;let extra='';
  if(key!=null&&score!=null){const old=parseFloat(store.get(key)),hi=G[key].best==='hoch',better=(isNaN(old)||(hi?score>old:score<old))&&!(hi&&score<=0);
    if(better){store.set(key,score);extra='<p><b>Neuer Rekord!</b></p>'}else if(!isNaN(old))extra='<p>Rekord: '+old+'</p>'}
  setTimeout(()=>{ov.innerHTML=`<h2>${title}</h2><p>${sub}</p>${extra}<button id="again">Nochmal</button><button class="alt" id="menu">Anderes Spiel</button>`;ov.hidden=false;
   document.getElementById('again').onclick=()=>start(gameId);document.getElementById('menu').onclick=menu;showBest()},350)}
function loop(t){const dt=Math.min(.033,(t-last)/1000||0);last=t;if(cur&&!over){cur.update(dt)}if(cur)cur.draw();raf=requestAnimationFrame(loop)}
function start(id){gameId=id;over=false;cur=G[id].init();ov.hidden=false;
  ov.innerHTML=`<h2>${G[id].name}</h2><p>${G[id].help}</p><button id="go">Los</button>`;
  document.querySelectorAll('.tile').forEach(t=>t.classList.toggle('on',t.dataset.id===id));
  document.getElementById('go').onclick=()=>{ov.hidden=true;over=false;last=performance.now();if(cur.reset)cur.reset()};
  over=true;ov.hidden=false;document.getElementById('go').onclick=()=>{over=false;ov.hidden=true;last=performance.now()};showBest()}
function menu(){cur=null;gameId=null;over=true;document.querySelectorAll('.tile').forEach(t=>t.classList.remove('on'));
  ov.hidden=false;ov.innerHTML='<h2>Spiel wählen</h2><p>Tippe links auf ein Spiel.</p>';bg();document.getElementById('best').textContent=''}
function showBest(){const el=document.getElementById('best');if(!gameId){el.textContent='';return}const b=store.get(gameId);const g=G[gameId];el.textContent=g.best&&b!=null?'Dein Rekord: '+b+(gameId==='reflex'?' ms':gameId==='stoptime'?' s Abweichung':''):''}
['down','move','up'].forEach(n=>cv.addEventListener('pointer'+(n==='down'?'down':n==='move'?'move':'up'),e=>{if(!cur||over)return;e.preventDefault();const p=pos(e);if(n==='down'&&cv.setPointerCapture)try{cv.setPointerCapture(e.pointerId)}catch(_){}
  if(cur[n])cur[n](p)}));
// Airhockey: Schläger folgt auch ohne Klick (Maus)
const tiles=document.getElementById('tiles');
Object.keys(G).forEach(id=>{const b=document.createElement('button');b.className='tile';b.dataset.id=id;b.innerHTML=`<img src="img/games/${G[id].img}.jpg" alt=""><span>${G[id].name}<small>${G[id].sub}</small></span>`;b.onclick=()=>{start(id);cv.scrollIntoView({block:'center',behavior:'smooth'})};tiles.appendChild(b)});
menu();raf=requestAnimationFrame(loop);
window.__ga={start,G,state:()=>({over,gameId})};
})();
