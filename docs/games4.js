/* Batch 3: Puck-Golf, Heisser Puck, Sumo, Curling, Slalom, Pong, Bowling, Darts, Korbjagd, Hürdenlauf, Takt, Billard */
(()=>{
'use strict';
const {W,H,OR,BL,rnd,text,circle,bg,bear,rrect}=GA,C=()=>GA.c,G=GAMES;
const reg=(id,o)=>{G[id]=Object.assign({name:NAMES[id],sub:'ca. '+SECS[id]+' Sekunden',help:RULES[id],tag:TAGS[id]},o)};
const dist=(a,b,c,d)=>Math.hypot(a-c,b-d);
function hudTime(t,s){text(Math.ceil(Math.max(0,t)),W-34,38,36,BL);if(s!=null)text(s,34,38,36,'#fff')}
const now=()=>performance.now();
function flick(g,p,onFlick){const d=g.drag;g.drag=null;if(!d)return;const dt=Math.max(.04,(now()-d.t)/1000),dx=p.x-d.x,dy=p.y-d.y;if(Math.hypot(dx,dy)>25)onFlick(dx/dt,dy/dt,dx,dy)}

reg('puckgolf',{best:'hoch',unit:' Löcher',cpuScore:s=>Math.round(2+s*7*rnd(.7,1.15)),
 init(o,end){const g={t:60,score:0,x:W/2,y:540,vx:0,vy:0,hx:0,hy:0,strokes:0,drag:null,msg:'',mt:0};
  const hole=()=>{g.hx=rnd(60,W-60);g.hy=rnd(120,320)};hole();
  g.down=p=>{if(Math.hypot(g.vx,g.vy)<8&&dist(p.x,p.y,g.x,g.y)<60)g.drag={x:p.x,y:p.y,t:now()}};
  g.up=p=>flick(g,p,(vx,vy,dx,dy)=>{const k=Math.min(1,520/Math.hypot(vx,vy));g.vx=vx*k*.9;g.vy=vy*k*.9;g.strokes++});
  g.update=dt=>{g.t-=dt;g.x+=g.vx*dt;g.y+=g.vy*dt;const f=Math.pow(.22,dt);g.vx*=f;g.vy*=f;
   if(g.x<14){g.x=14;g.vx=Math.abs(g.vx)*.8}if(g.x>W-14){g.x=W-14;g.vx=-Math.abs(g.vx)*.8}if(g.y<90){g.y=90;g.vy=Math.abs(g.vy)*.8}if(g.y>H-30){g.y=H-30;g.vy=-Math.abs(g.vy)*.8}
   if(dist(g.x,g.y,g.hx,g.hy)<18&&Math.hypot(g.vx,g.vy)<420){g.score++;g.msg=g.strokes<=1?'Hole in one!':'Eingelocht!';g.mt=.8;g.strokes=0;g.vx=g.vy=0;g.x=W/2;g.y=540;hole()}
   g.mt-=dt;if(g.t<=0)end({score:g.score,title:'Zeit um!',sub:g.score+' Löcher'})};
  g.draw=()=>{const c=C();bg();c.fillStyle='rgba(31,191,91,.12)';c.fillRect(0,90,W,H);circle(g.hx,g.hy,17,'#000');c.strokeStyle='#fff';c.lineWidth=2;c.beginPath();c.moveTo(g.hx,g.hy);c.lineTo(g.hx,g.hy-44);c.stroke();c.fillStyle=OR;c.fillRect(g.hx,g.hy-44,22,12);
   circle(g.x,g.y,12,'#fff',10);if(g.drag)text('Loslassen = Schlag',W/2,H-30,20,BL);hudTime(g.t,g.score);text('Schläge '+g.strokes,W/2,38,22,'#fff');if(g.mt>0)text(g.msg,W/2,300,40,'#1fbf5b')};
  return g}});

reg('hotpuck',{best:'hoch',unit:' überlebt',cpuScore:s=>Math.round(2+s*3*rnd(.6,1.3)),
 init(o,end){const pos=[{x:W/2,y:520},{x:70,y:200},{x:W/2,y:130},{x:W-70,y:200}],g={holder:0,lives:3,round:0,rt:rnd(7,11),need:0,hold:0,ok:0,msg:'',mt:0,heat:0};
  g.pass=()=>{let n;do{n=1+Math.floor(Math.random()*3)}while(n===g.holder);g.holder=n;g.hold=rnd(.5,1.2)-o.skill*.3};
  g.down=p=>{if(g.holder===0&&g.mt<=0){g.need++;if(g.need>=5){g.need=0;g.pass()}}};
  g.update=dt=>{if(g.mt>0){g.mt-=dt;if(g.mt<=0){g.round++;if(g.lives<=0||g.round>=6)end({score:g.ok,title:'Spiel vorbei',sub:g.ok+' von '+g.round+' Runden überstanden'});else{g.rt=rnd(7,11);g.heat=0;g.holder=Math.floor(Math.random()*4)}}return}
   g.rt-=dt;g.heat=1-g.rt/11;if(g.holder>0){g.hold-=dt;if(g.hold<=0){const n=Math.floor(Math.random()*4);g.holder=n===g.holder?0:n;if(g.holder===0)g.need=0;else g.hold=rnd(.5,1.2)}}
   if(g.rt<=0){if(g.holder===0){g.lives--;g.msg='BUMM! Du hattest ihn'}else{g.ok++;g.msg='BUMM! Bär '+g.holder+' hatte ihn'}g.mt=1.6}};
  g.draw=()=>{const c=C();bg();pos.forEach((p,i)=>{bear(p.x,p.y,i?24:30,i?['#7fd8ff','#ffc400','#1fbf5b'][i-1]:OR)});
   const h=pos[g.holder];circle(h.x,h.y-48,16+g.heat*10,`hsl(${30-g.heat*30},100%,55%)`,24);
   text(g.holder===0?'TIPPEN! '+g.need+' / 5':'Ausweichen!',W/2,330,30,g.holder===0?'#fff':BL);text('♥'.repeat(Math.max(0,g.lives)),W-50,40,26,'#d9293d');text('Runde '+Math.min(6,g.round+1)+' / 6',90,40,24,OR);if(g.mt>0)text(g.msg,W/2,420,26,'#fff')};
  return g}});

reg('sumo',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(15+s*40*rnd(.6,1.1)),
 init(o,end){const cx=W/2,cy=320,b=[{x:cx,y:cy+60,vx:0,vy:0,me:true,out:false},{x:cx-60,y:cy-40,vx:0,vy:0},{x:cx+60,y:cy-40,vx:0,vy:0},{x:cx,y:cy-85,vx:0,vy:0}].map(a=>Object.assign({r:22},a));
  const g={t:0,R:165,tx:cx,ty:cy+60,kills:0};
  g.down=g.move=p=>{g.tx=p.x;g.ty=p.y};
  g.update=dt=>{g.t+=dt;g.R=Math.max(70,165-g.t*2.2);
   b.forEach(a=>{if(a.out)return;if(a.me){const dx=g.tx-a.x,dy=g.ty-a.y,d=Math.hypot(dx,dy)||1,s=Math.min(d*8,230);a.vx+=(dx/d*s-a.vx)*Math.min(1,dt*6);a.vy+=(dy/d*s-a.vy)*Math.min(1,dt*6)}
    else{const t=b.find(x=>x.me&&!x.out)||b[0],o2=b.filter(x=>!x.out&&x!==a);let tg=t;const dx=tg.x-a.x,dy=tg.y-a.y,d=Math.hypot(dx,dy)||1,sp=70+o.skill*150;a.vx+=(dx/d*sp-a.vx)*Math.min(1,dt*3);a.vy+=(dy/d*sp-a.vy)*Math.min(1,dt*3)}
    a.x+=a.vx*dt;a.y+=a.vy*dt});
   for(let i=0;i<b.length;i++)for(let j=i+1;j<b.length;j++){const p=b[i],q=b[j];if(p.out||q.out)continue;const dx=q.x-p.x,dy=q.y-p.y,d=Math.hypot(dx,dy),m=p.r+q.r;if(d<m&&d>0){const nx=dx/d,ny=dy/d,ov=m-d;p.x-=nx*ov/2;p.y-=ny*ov/2;q.x+=nx*ov/2;q.y+=ny*ov/2;const rel=(q.vx-p.vx)*nx+(q.vy-p.vy)*ny;if(rel<0){const imp=-rel*1.9;p.vx-=nx*imp;p.vy-=ny*imp;q.vx+=nx*imp;q.vy+=ny*imp}}}
   b.forEach(a=>{if(!a.out&&dist(a.x,a.y,cx,cy)>g.R+a.r*.4){a.out=true;if(!a.me)g.kills++}});
   const me=b[0];if(g.t>75)end({score:Math.round(g.t)+g.kills*15,title:'Zeit um!',sub:Math.round(g.t)+' s + '+g.kills+' Bären'});else if(me.out)end({score:Math.round(g.t)+g.kills*15,title:'Runtergeschoben!',sub:Math.round(g.t)+' s + '+g.kills+' Bären'});
   else if(b.slice(1).every(x=>x.out))end({score:Math.round(g.t)+g.kills*15+30,title:'Letzter Bär!',sub:Math.round(g.t)+' s + '+g.kills+' Bären + Sieg'})};
  g.draw=()=>{const c=C();bg();circle(cx,cy,g.R,'#7fd8ff');circle(cx,cy,g.R-6,'#dff5ff');b.forEach(a=>{if(!a.out)bear(a.x,a.y,a.r,a.me?OR:'#556b84')});text(Math.round(g.t)+' s',W/2,50,36,BL);text('Zieh deinen Bären mit dem Finger',W/2,H-40,20,'#fff')};
  return g}});

reg('curling',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(15+s*25*rnd(.7,1.1)),
 init(o,end){const hx=W/2,hy=170,g={stones:[],n:0,cur:null,drag:null,score:0,msg:''};
  const ready=()=>{g.cur={x:W/2,y:560,vx:0,vy:0,r:20,moving:false};g.stones.push(g.cur)};ready();
  g.down=p=>{if(g.cur&&!g.cur.moving&&dist(p.x,p.y,g.cur.x,g.cur.y)<80)g.drag={x:p.x,y:p.y,sx:p.x,sy:p.y,t:now()}};g.move=p=>{if(g.drag){g.drag.x=p.x;g.drag.y=p.y}};
  g.up=p=>{const d=g.drag;g.drag=null;if(!d)return;const dx=d.sx-p.x,dy=d.sy-p.y,pw=Math.min(1,Math.hypot(dx,dy)/160);if(dy<-20&&false)return;if(Math.hypot(dx,dy)<24)return;g.cur.vx=dx/Math.hypot(dx,dy)*pw*620;g.cur.vy=dy/Math.hypot(dx,dy)*pw*620;g.cur.moving=true};
  g.update=dt=>{let mv=false;g.stones.forEach(s=>{if(Math.hypot(s.vx,s.vy)>6){mv=true;s.x+=s.vx*dt;s.y+=s.vy*dt;const f=Math.pow(.45,dt);s.vx*=f;s.vy*=f}else{s.vx=s.vy=0}});
   for(let i=0;i<g.stones.length;i++)for(let j=i+1;j<g.stones.length;j++){const a=g.stones[i],b=g.stones[j],dx=b.x-a.x,dy=b.y-a.y,d=Math.hypot(dx,dy);if(d<40&&d>0){const nx=dx/d,ny=dy/d;b.x=a.x+nx*40;b.y=a.y+ny*40;const rel=(b.vx-a.vx)*nx+(b.vy-a.vy)*ny;if(rel<0){a.vx+=nx*-rel;a.vy+=ny*-rel;b.vx-=nx*-rel;b.vy-=ny*-rel}}}
   g.stones=g.stones.filter(s=>{if(s.x<10||s.x>W-10||s.y<60||s.y>H+30){if(s===g.cur)g.cur=g.cur;return s.y<=H+30&&s.x>0&&s.x<W&&s.y>40}return true});
   if(g.cur&&g.cur.moving&&!mv){g.n++;if(g.n>=5){g.score=g.stones.reduce((t,s)=>t+Math.max(0,Math.round(10-dist(s.x,s.y,hx,hy)/9)),0);end({score:g.score,title:g.score+' Punkte',sub:'5 Steine gespielt'})}else ready()}
   if(g.cur&&!g.stones.includes(g.cur)&&g.cur.moving&&!mv){g.n++;if(g.n>=5)end({score:g.stones.reduce((t,s)=>t+Math.max(0,Math.round(10-dist(s.x,s.y,hx,hy)/9)),0),title:'Fertig',sub:'5 Steine gespielt'});else ready()}};
  g.draw=()=>{const c=C();bg();c.fillStyle='rgba(127,216,255,.08)';c.fillRect(30,60,W-60,H-60);[[75,'#38c8ff'],[48,'#fff'],[22,'#d9293d']].forEach(([r,col],i)=>{circle(hx,hy,r,i===1?'#dff5ff':col)});
   g.stones.forEach(s=>{circle(s.x,s.y,s.r,'#7a8794');circle(s.x,s.y,s.r-6,OR)});
   if(g.drag){const c2=C();c2.strokeStyle=BL;c2.lineWidth=4;c2.setLineDash([8,8]);c2.beginPath();c2.moveTo(g.cur.x,g.cur.y);c2.lineTo(g.cur.x+(g.drag.sx-g.drag.x),g.cur.y+(g.drag.sy-g.drag.y));c2.stroke();c2.setLineDash([])}
   text('Stein '+Math.min(5,g.n+1)+' / 5',W/2,34,26,OR);text('Zurückziehen und loslassen',W/2,H-24,18,'rgba(255,255,255,.7)')};
  return g}});

reg('slalom',{best:'hoch',unit:' Tore',cpuScore:s=>Math.round(6+s*22*rnd(.7,1.1)),
 init(o,end){const g={t:45,x:W/2,tx:W/2,score:0,gates:[],sp:0,spd:180,fx:0};
  g.down=g.move=p=>{g.tx=p.x};
  g.update=dt=>{g.t-=dt;g.spd=180+(45-g.t)*3;g.x+=Math.max(-420*dt,Math.min(420*dt,g.tx-g.x));g.sp-=dt;if(g.sp<=0){g.sp=rnd(.9,1.3)*200/g.spd*1.2;g.gates.push({x:rnd(90,W-90),y:-20,got:false})}
   g.gates.forEach(t=>{t.y+=g.spd*dt;if(!t.got&&t.y>540){t.got=true;if(Math.abs(g.x-t.x)<46-10){g.score++;g.fx=.3;g.good=true}else{g.fx=.3;g.good=false;g.score=Math.max(0,g.score-1)}}});g.gates=g.gates.filter(t=>t.y<700);
   if(g.t<=0)end({score:g.score,title:'Zeit um!',sub:g.score+' saubere Tore'})};
  g.draw=()=>{const c=C();bg();c.fillStyle='rgba(255,255,255,.04)';c.fillRect(0,0,W,H);g.gates.forEach(t=>{[-46,46].forEach(dx=>{c.fillStyle=t.got?'#556b84':OR;c.beginPath();c.moveTo(t.x+dx,t.y-16);c.lineTo(t.x+dx-12,t.y+14);c.lineTo(t.x+dx+12,t.y+14);c.closePath();c.fill()})});
   circle(g.x,540,13,'#fff',10);hudTime(g.t,g.score);if(g.fx>0)text(g.good?'+1':'Umgeworfen −1',W/2,200,30,g.good?'#1fbf5b':'#d9293d')};
  return g}});

reg('pong',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(10+s*50*rnd(.7,1.1)),
 init(o,end){const L=20,T=170,S=320,g={px:W/2,ball:{x:W/2,y:T+S/2,vx:140,vy:160},lives:[3,3,3,3],pts:0,t:0,cpu:[W/2,T+S/2,T+S/2]};
  g.down=g.move=p=>{g.px=Math.max(L+36,Math.min(L+S-36,p.x))};
  const reset=()=>{g.ball={x:W/2,y:T+S/2,vx:rnd(-160,160),vy:rnd(140,200)*(Math.random()<.5?1:-1)}};
  g.update=dt=>{g.t+=dt;const b=g.ball;b.x+=b.vx*dt;b.y+=b.vy*dt;const sp=Math.hypot(b.vx,b.vy);if(sp<420){b.vx*=1+dt*.04;b.vy*=1+dt*.04}
   const ms=60+o.skill*260;const tr=(i,tgt)=>{g.cpu[i]+=Math.max(-ms*dt,Math.min(ms*dt,tgt-g.cpu[i]))};tr(0,b.x);tr(1,b.y);tr(2,b.y);
   const hit=(cond,fn,k)=>{if(cond){fn();return true}};
   if(b.y>T+S-12){if(g.lives[0]>0&&Math.abs(b.x-g.px)<42){b.y=T+S-12;b.vy=-Math.abs(b.vy);b.vx+=(b.x-g.px)*3;g.pts++}else if(g.lives[0]<=0){b.y=T+S-12;b.vy=-Math.abs(b.vy)}else if(b.y>T+S+10){g.lives[0]--;reset()}}
   if(b.y<T+12){if(g.lives[1]>0&&Math.abs(b.x-g.cpu[0])<42){b.y=T+12;b.vy=Math.abs(b.vy);b.vx+=(b.x-g.cpu[0])*3}else if(g.lives[1]<=0){b.y=T+12;b.vy=Math.abs(b.vy)}else if(b.y<T-10){g.lives[1]--;if(g.lives[1]<=0)g.pts+=20;reset()}}
   if(b.x<L+12){if(g.lives[2]>0&&Math.abs(b.y-g.cpu[1])<42){b.x=L+12;b.vx=Math.abs(b.vx);b.vy+=(b.y-g.cpu[1])*3}else if(g.lives[2]<=0){b.x=L+12;b.vx=Math.abs(b.vx)}else if(b.x<L-10){g.lives[2]--;if(g.lives[2]<=0)g.pts+=20;reset()}}
   if(b.x>L+S-12){if(g.lives[3]>0&&Math.abs(b.y-g.cpu[2])<42){b.x=L+S-12;b.vx=-Math.abs(b.vx);b.vy+=(b.y-g.cpu[2])*3}else if(g.lives[3]<=0){b.x=L+S-12;b.vx=-Math.abs(b.vx)}else if(b.x>L+S+10){g.lives[3]--;if(g.lives[3]<=0)g.pts+=20;reset()}}
   const sc=g.pts+Math.round(g.t/3);
   if(g.lives[0]<=0)end({score:sc,title:'Ausgeschieden',sub:sc+' Punkte'});else if(g.lives[1]<=0&&g.lives[2]<=0&&g.lives[3]<=0)end({score:sc+30,title:'Alle besiegt!',sub:(sc+30)+' Punkte'});else if(g.t>90)end({score:sc,title:'Zeit um!',sub:sc+' Punkte'})};
  g.draw=()=>{const c=C();bg();c.strokeStyle=BL;c.lineWidth=3;c.strokeRect(L,T,S,S);const pd=(x,y,h,col,a)=>{c.fillStyle=col;rrect(h?x-36:x-6,h?y-6:y-36,h?72:12,h?12:72,6);c.fill()};
   pd(g.px,T+S,true,OR);if(g.lives[1]>0)pd(g.cpu[0],T,true,'#7fd8ff');if(g.lives[2]>0)pd(L,g.cpu[1],false,'#ffc400');if(g.lives[3]>0)pd(L+S,g.cpu[2],false,'#1fbf5b');
   circle(g.ball.x,g.ball.y,9,'#fff',12);text('♥'.repeat(Math.max(0,g.lives[0])),W/2,T+S+50,26,'#d9293d');text('Punkte '+(g.pts+Math.round(g.t/3)),W/2,60,32,'#fff');text('Dein Schläger unten',W/2,H-40,20,BL)};
  return g}});

reg('bowling',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(20+s*30*rnd(.7,1.1)),
 init(o,end){const g={throw:0,score:0,ball:null,pins:[],drag:null,msg:'',mt:0,wait:0,last:0};
  const rack=()=>{g.pins=[];let k=0;for(let r=0;r<4;r++)for(let c=0;c<=r;c++){g.pins.push({x:W/2+(c-r/2)*26,y:130+r*22,vx:0,vy:0,r:8,down:false,sx:W/2+(c-r/2)*26,sy:130+r*22})}};rack();
  const newBall=()=>{g.ball={x:W/2,y:560,vx:0,vy:0,r:14,rolling:false}};newBall();
  g.down=p=>{if(g.ball&&!g.ball.rolling&&g.wait<=0)g.drag={x:p.x,y:p.y,t:now()}};
  g.up=p=>flick(g,p,(vx,vy,dx,dy)=>{if(dy>-30)return;const k=Math.min(1,800/Math.hypot(vx,vy));g.ball.vx=vx*k*.5;g.ball.vy=Math.min(-420,vy*k);g.ball.rolling=true;g.sx=g.ball.x});
  g.update=dt=>{if(g.wait>0){g.wait-=dt;if(g.wait<=0){g.throw++;if(g.throw>=5)end({score:g.score,title:g.score+' Punkte',sub:'5 Würfe'});else{rack();newBall()}}return}
   if(!g.ball.rolling)return;for(let s=0;s<3;s++){const d=dt/3,b=g.ball;b.x+=b.vx*d;b.y+=b.vy*d;
    if(b.x<60+b.r){b.x=60+b.r;b.vx=Math.abs(b.vx)}if(b.x>W-60-b.r){b.x=W-60-b.r;b.vx=-Math.abs(b.vx)}
    const all=[b,...g.pins.filter(p=>!p.gone)];all.forEach(p=>{if(p!==b){p.x+=p.vx*d;p.y+=p.vy*d;p.vx*=Math.pow(.5,d);p.vy*=Math.pow(.5,d);if(p.x<70||p.x>W-70){p.vx*=-.5;p.x=Math.max(70,Math.min(W-70,p.x))}if(p.y<90){p.vy=Math.abs(p.vy)*.3;p.y=90}}});
    for(let i=0;i<all.length;i++)for(let j=i+1;j<all.length;j++){const a=all[i],c2=all[j],dx=c2.x-a.x,dy=c2.y-a.y,dd=Math.hypot(dx,dy),m=a.r+c2.r;if(dd<m&&dd>0){const nx=dx/dd,ny=dy/dd,ma=a===b?5:1,mb=c2===b?5:1,ov=m-dd;a.x-=nx*ov*mb/(ma+mb);a.y-=ny*ov*mb/(ma+mb);c2.x+=nx*ov*ma/(ma+mb);c2.y+=ny*ov*ma/(ma+mb);const rel=(c2.vx-a.vx)*nx+(c2.vy-a.vy)*ny;if(rel<0){const imp=-1.7*rel/(1/ma+1/mb);a.vx-=nx*imp/ma;a.vy-=ny*imp/ma;c2.vx+=nx*imp/mb;c2.vy+=ny*imp/mb}}}}
   g.pins.forEach(p=>{if(!p.down&&dist(p.x,p.y,p.sx,p.sy)>10)p.down=true});
   const moving=g.ball.y>70&&(Math.hypot(g.ball.vx,g.ball.vy)>20||g.pins.some(p=>Math.hypot(p.vx,p.vy)>12));
   if(g.ball.y<60){g.ball.vx=g.ball.vy=0}
   if(!moving||g.ball.y<60&&!g.pins.some(p=>Math.hypot(p.vx,p.vy)>12)){const n=g.pins.filter(p=>p.down).length;let pts=n+(n===10?5:0);g.score+=pts;g.msg=n===10?'STRIKE! +'+pts:n+' Pins';g.mt=1.3;g.wait=1.3;g.ball.rolling=false;g.ball.vx=g.ball.vy=0}};
  g.draw=()=>{const c=C();bg();c.fillStyle='#b98a4a';c.fillRect(60,70,W-120,H-70);c.fillStyle='#1b1209';c.fillRect(0,70,60,H);c.fillRect(W-60,70,60,H);
   g.pins.forEach(p=>{circle(p.x,p.y,p.r,p.down?'#caa':'#fff')});circle(g.ball.x,g.ball.y,g.ball.r,'#222');circle(g.ball.x-4,g.ball.y-4,3,'#555');
   text('Wurf '+Math.min(5,g.throw+1)+' / 5',W/2,34,26,OR);text(g.score,W-34,34,30,'#fff');if(g.mt>0)text(g.msg,W/2,300,36,'#fff');else if(!g.ball.rolling)text('Kräftig nach oben wischen',W/2,H-18,18,'#fff')};
  return g}});

reg('darts',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(60+s*120*rnd(.7,1.1)),
 init(o,end){const cx=W/2,cy=300,g={n:0,score:0,t:0,darts:[],msg:'',mt:0};
  g.down=()=>{if(g.mt>0)return;const amp=95-0*o.skill,x=cx+Math.sin(g.t*2.3)*amp*Math.cos(g.t*.7),y=cy+Math.sin(g.t*1.9+1)*amp;const d=dist(x,y,cx,cy);const pts=d<10?50:d<25?25:d<45?15:d<75?10:d<105?5:0;g.score+=pts;g.darts.push({x,y});g.msg=pts?'+'+pts:'Daneben';g.mt=.7;g.n++};
  g.update=dt=>{g.t+=dt;if(g.mt>0){g.mt-=dt;if(g.mt<=0&&g.n>=6)end({score:g.score,title:g.score+' Punkte',sub:'6 Pfeile'})}};
  g.draw=()=>{const c=C();bg();[[105,'#222'],[75,'#d9293d'],[45,'#1fbf5b'],[25,'#ffc400'],[10,'#d9293d']].forEach(([r,col])=>circle(cx,cy,r,col));circle(cx,cy,105,'rgba(255,255,255,.08)');
   g.darts.forEach(d=>{circle(d.x,d.y,5,'#fff')});const amp=95,x=cx+Math.sin(g.t*2.3)*amp*Math.cos(g.t*.7),y=cy+Math.sin(g.t*1.9+1)*amp;if(g.mt<=0){c.strokeStyle=BL;c.lineWidth=3;c.beginPath();c.arc(x,y,16,0,7);c.moveTo(x-24,y);c.lineTo(x+24,y);c.moveTo(x,y-24);c.lineTo(x,y+24);c.stroke()}
   text('Pfeil '+Math.min(6,g.n+1)+' / 6',W/2,60,32,OR);text(g.score,W/2,500,64,'#fff');if(g.mt>0)text(g.msg,W/2,570,36,'#fff');else text('Tippen zum Werfen',W/2,570,24,BL)};
  return g}});

reg('hoops',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(5+s*16*rnd(.7,1.1)),
 init(o,end){const g={t:30,score:0,streak:0,hx:W/2,ht:0,ball:{x:W/2,y:560,vx:0,vy:0,fly:false},drag:null,msg:'',mt:0};
  g.down=p=>{if(!g.ball.fly&&dist(p.x,p.y,g.ball.x,g.ball.y)<70)g.drag={x:p.x,y:p.y,t:now()}};
  g.up=p=>flick(g,p,(vx,vy,dx,dy)=>{if(dy>-30)return;const k=Math.min(1,1100/Math.hypot(vx,vy));g.ball.vx=vx*k*.45;g.ball.vy=Math.min(-600,vy*k);g.ball.fly=true});
  g.update=dt=>{g.t-=dt;g.ht+=dt*(1+g.score*.05);g.hx=W/2+Math.sin(g.ht*1.3)*110;const b=g.ball;if(b.fly){b.x+=b.vx*dt;b.y+=b.vy*dt;
    if(b.y<=190){if(Math.abs(b.x-g.hx)<34){g.streak++;g.score+=1+Math.floor(g.streak/3);g.msg='KORB!'+(g.streak>2?' Serie '+g.streak:'');}else{g.streak=0;g.msg='Daneben'}g.mt=.6;b.x=W/2;b.y=560;b.fly=false}
    if(b.x<-30||b.x>W+30){g.streak=0;g.msg='Daneben';g.mt=.6;b.x=W/2;b.y=560;b.fly=false}}
   g.mt-=dt;if(g.t<=0)end({score:g.score,title:'Zeit um!',sub:g.score+' Punkte'})};
  g.draw=()=>{const c=C();bg();c.strokeStyle='#fff';c.lineWidth=4;c.strokeRect(g.hx-40,130,80,6);c.strokeStyle=OR;c.lineWidth=6;c.beginPath();c.moveTo(g.hx-34,186);c.lineTo(g.hx+34,186);c.stroke();c.fillStyle='rgba(255,255,255,.08)';c.fillRect(g.hx-34,136,68,50);
   circle(g.ball.x,g.ball.y,15,OR,10);hudTime(g.t,g.score);if(g.mt>0)text(g.msg,W/2,320,32,g.msg[0]==='K'?'#1fbf5b':'#d9293d')};
  return g}});

reg('hurdles',{best:'hoch',unit:' Hürden',cpuScore:s=>Math.round(5+s*18*rnd(.7,1.1)),
 init(o,end){const g={t:40,y:0,vy:0,hurd:[],sp:0,cleared:0,stum:0,spd:260,fx:0};
  g.down=()=>{if(g.y===0)g.vy=-700};
  g.update=dt=>{g.t-=dt;g.spd=260+(40-g.t)*5;g.sp-=dt;if(g.sp<=0){g.sp=rnd(.9,1.5)*260/g.spd*1.2;g.hurd.push({x:W+20,done:false})}
   if(g.vy!==0||g.y<0){g.vy+=2400*dt;g.y+=g.vy*dt;if(g.y>=0){g.y=0;g.vy=0}}
   g.hurd.forEach(h=>{h.x-=g.spd*dt;if(!h.done&&h.x<100){h.done=true;if(g.y<-34)g.cleared++;else{g.stum++;g.fx=.4}}});g.hurd=g.hurd.filter(h=>h.x>-30);g.fx-=dt;
   if(g.stum>=3)end({score:g.cleared,title:'3× gestolpert',sub:g.cleared+' Hürden geschafft'});if(g.t<=0)end({score:g.cleared,title:'Ziel erreicht',sub:g.cleared+' Hürden geschafft'})};
  g.draw=()=>{const c=C();bg();c.fillStyle='#243a57';c.fillRect(0,420,W,6);c.fillStyle='rgba(56,200,255,.12)';c.fillRect(0,426,W,H);g.hurd.forEach(h=>{c.fillStyle='#fff';c.fillRect(h.x-4,380,8,42);c.fillStyle=OR;c.fillRect(h.x-16,376,32,8)});
   c.globalAlpha=g.fx>0&&Math.floor(g.fx*12)%2?.4:1;bear(100,398+g.y,22,OR);c.globalAlpha=1;text('Tippen zum Springen',W/2,520,24,BL);text(g.cleared+' Hürden',W/2,60,36,'#fff');text('Stolperer '+g.stum+' / 3',W/2,100,22,'#d9293d');text(Math.ceil(Math.max(0,g.t)),W-34,38,32,BL)};
  return g}});

reg('rhythm',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(40+s*80*rnd(.7,1.1)),
 init(o,end){const g={t:40,notes:[],sp:0,score:0,fx:'',ft:0,time:0};const lx=k=>45+k*90,hy=540;
  g.down=p=>{const k=Math.max(0,Math.min(3,Math.floor((p.x-0)/90)));let best=null;g.notes.forEach(n=>{if(n.l===k&&!n.hit&&Math.abs(n.y-hy)<60&&(!best||Math.abs(n.y-hy)<Math.abs(best.y-hy)))best=n});
   if(best){best.hit=true;const d=Math.abs(best.y-hy);g.score+=d<20?3:1;g.fx=d<20?'PERFEKT':'Gut';g.ft=.3}else{g.fx='Daneben';g.ft=.3}};
  g.update=dt=>{g.t-=dt;g.sp-=dt;if(g.sp<=0){g.sp=rnd(.28,.6);g.notes.push({l:Math.floor(Math.random()*4),y:-20,hit:false})}g.notes.forEach(n=>n.y+=330*dt);g.notes=g.notes.filter(n=>n.y<H+20);g.ft-=dt;if(g.t<=0)end({score:g.score,title:'Song vorbei',sub:g.score+' Punkte'})};
  g.draw=()=>{const c=C();bg();for(let k=0;k<4;k++){c.fillStyle=k%2?'rgba(56,200,255,.07)':'rgba(255,106,0,.07)';c.fillRect(k*90,0,90,H);circle(lx(k),hy,26,'rgba(255,255,255,.15)')}
   g.notes.forEach(n=>{if(!n.hit)circle(lx(n.l),n.y,22,['#d9293d','#1fbf5b','#38c8ff','#ffc400'][n.l],10)});hudTime(g.t,g.score);if(g.ft>0)text(g.fx,W/2,300,32,'#fff')};
  return g}});

reg('billiard',{best:'hoch',unit:' versenkt',cpuScore:s=>Math.round(2+s*5*rnd(.7,1.15)),
 init(o,end){const L=24,T=110,TW=W-48,TH=440,pk=[[L,T],[L+TW,T],[L,T+TH],[L+TW,T+TH],[L,T+TH/2],[L+TW,T+TH/2]];
  const bs=[{x:W/2,y:T+TH-90,vx:0,vy:0,r:13,cue:true}];for(let r=0;r<3;r++)for(let c=0;c<=r;c++)bs.push({x:W/2+(c-r/2)*28,y:T+130+r*26,vx:0,vy:0,r:13});
  const g={shots:0,score:0,drag:null,msg:'',mt:0,moving:false};
  g.down=p=>{const q=bs[0];if(!g.moving&&!q.gone&&dist(p.x,p.y,q.x,q.y)<80)g.drag={sx:p.x,sy:p.y,x:p.x,y:p.y}};g.move=p=>{if(g.drag){g.drag.x=p.x;g.drag.y=p.y}};
  g.up=p=>{const d=g.drag;g.drag=null;if(!d)return;const dx=d.sx-p.x,dy=d.sy-p.y,l=Math.hypot(dx,dy);if(l<20)return;const pw=Math.min(1,l/150)*900;bs[0].vx=dx/l*pw;bs[0].vy=dy/l*pw;g.shots++;g.moving=true};
  g.update=dt=>{let mv=false;for(let s=0;s<2;s++){const d=dt/2;bs.forEach(b=>{if(b.gone)return;b.x+=b.vx*d;b.y+=b.vy*d;const f=Math.pow(.38,d);b.vx*=f;b.vy*=f;if(Math.hypot(b.vx,b.vy)<8){b.vx=b.vy=0}else mv=true;
     if(b.x<L+b.r){b.x=L+b.r;b.vx=Math.abs(b.vx)*.9}if(b.x>L+TW-b.r){b.x=L+TW-b.r;b.vx=-Math.abs(b.vx)*.9}if(b.y<T+b.r){b.y=T+b.r;b.vy=Math.abs(b.vy)*.9}if(b.y>T+TH-b.r){b.y=T+TH-b.r;b.vy=-Math.abs(b.vy)*.9}
     pk.forEach(([px,py])=>{if(dist(b.x,b.y,px,py)<22){b.gone=true;if(b.cue){g.score=Math.max(0,g.score-1);g.msg='Weiss versenkt −1'}else{g.score++;g.msg='Versenkt!'}g.mt=.8}})});
    for(let i=0;i<bs.length;i++)for(let j=i+1;j<bs.length;j++){const a=bs[i],b=bs[j];if(a.gone||b.gone)continue;const dx=b.x-a.x,dy=b.y-a.y,dd=Math.hypot(dx,dy);if(dd<26&&dd>0){const nx=dx/dd,ny=dy/dd,ov=26-dd;a.x-=nx*ov/2;a.y-=ny*ov/2;b.x+=nx*ov/2;b.y+=ny*ov/2;const rel=(b.vx-a.vx)*nx+(b.vy-a.vy)*ny;if(rel<0){a.vx+=nx*-rel;a.vy+=ny*-rel;b.vx-=nx*-rel;b.vy-=ny*-rel}}}}
   g.mt-=dt;if(g.moving&&!mv){g.moving=false;if(bs[0].gone){bs[0].gone=false;bs[0].x=W/2;bs[0].y=T+TH-90;bs[0].vx=bs[0].vy=0}
    if(bs.slice(1).every(b=>b.gone)||g.shots>=8)end({score:g.score,title:g.score+' versenkt',sub:g.shots+' Schüsse'})}};
  g.draw=()=>{const c=C();bg();c.fillStyle='#0f5a33';rrect(L-10,T-10,TW+20,TH+20,16);c.fill();c.fillStyle='#14783f';c.fillRect(L,T,TW,TH);pk.forEach(([x,y])=>circle(x,y,20,'#000'));
   bs.forEach(b=>{if(!b.gone)circle(b.x,b.y,b.r,b.cue?'#fff':OR,b.cue?10:0)});if(g.drag){const q=bs[0];c.strokeStyle='#fff';c.lineWidth=3;c.setLineDash([6,8]);c.beginPath();c.moveTo(q.x,q.y);c.lineTo(q.x+(g.drag.sx-g.drag.x)*1.4,q.y+(g.drag.sy-g.drag.y)*1.4);c.stroke();c.setLineDash([])}
   text('Schuss '+Math.min(8,g.shots+1)+' / 8',W/2,50,28,OR);text(g.score+' versenkt',W/2,90,24,'#fff');if(g.mt>0)text(g.msg,W/2,H-60,28,'#fff')};
  return g}});
})();
