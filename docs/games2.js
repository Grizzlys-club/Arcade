/* Batch 1: Penalty, Torwart, Ballregen, Power-Schuss, Ballhalten, Quiz, Duell, Sprint, Ninja, Turm */
(()=>{
'use strict';
const {W,H,OR,BL,rnd,text,circle,bg,bear,rrect}=GA,C=()=>GA.c,G=GAMES;
const reg=(id,o)=>{G[id]=Object.assign({name:NAMES[id],sub:'ca. '+SECS[id]+' Sekunden',help:RULES[id],tag:TAGS[id]},o)};
const dist=(a,b,c,d)=>Math.hypot(a-c,b-d);
const pr=(x,y)=>({x,y});
function hudTime(t,s){text(Math.ceil(Math.max(0,t)),W-34,38,36,BL);if(s!=null)text(s,34,38,36,'#fff')}

reg('penalty',{best:'hoch',unit:' Tore',cpuScore:s=>Math.round(3+s*14*rnd(.7,1.15)),
 init(o,end){const g={t:40,score:0,ball:{x:W/2,y:540,vx:0,vy:0,fly:false},gx:0,gk:W/2,sp:1,msg:'',mt:0,drag:null};
  g.down=p=>{if(!g.ball.fly&&dist(p.x,p.y,g.ball.x,g.ball.y)<70)g.drag={x:p.x,y:p.y,t:performance.now()}};
  g.up=p=>{if(!g.drag)return;const dt=Math.max(.05,(performance.now()-g.drag.t)/1000),dx=p.x-g.drag.x,dy=p.y-g.drag.y;g.drag=null;if(dy<-30){g.ball.vx=Math.max(-420,Math.min(420,dx/dt*.6));g.ball.vy=-Math.max(520,Math.min(1100,-dy/dt*.9));g.ball.fly=true}};
  g.update=dt=>{g.t-=dt;g.gx+=dt*(1.4+g.sp*.35);g.gk=W/2+Math.sin(g.gx)*(70+g.sp*8);
   const b=g.ball;if(b.fly){b.x+=b.vx*dt;b.y+=b.vy*dt;
    if(b.y<=160){const inGoal=b.x>80&&b.x<280;if(inGoal&&Math.abs(b.x-g.gk)>34){g.score++;g.sp+=.5;g.msg='TOR!';}else g.msg=inGoal?'GEHALTEN':'DANEBEN';g.mt=.8;b.x=W/2;b.y=540;b.fly=false}
    if(b.y<0||b.x<-30||b.x>W+30){g.msg='DANEBEN';g.mt=.8;b.x=W/2;b.y=540;b.fly=false}}
   g.mt-=dt;if(g.t<=0)end({score:g.score,title:'Abpfiff!',sub:g.score+' Tore'})};
  g.draw=()=>{const c=C();bg();c.strokeStyle='#fff';c.lineWidth=4;c.strokeRect(80,100,200,60);c.fillStyle='rgba(255,255,255,.08)';c.fillRect(80,100,200,60);
   c.fillStyle=OR;rrect(g.gk-34,118,68,26,8);c.fill();circle(g.gk,100+31,4,'#111');
   circle(g.ball.x,g.ball.y,14,'#fff',12);if(g.drag)text('Nach oben wischen',W/2,600,22,BL);
   hudTime(g.t,g.score);if(g.mt>0)text(g.msg,W/2,300,52,g.msg==='TOR!'?'#1fbf5b':'#d9293d')};
  return g}});

reg('goalie',{best:'hoch',unit:' Paraden',cpuScore:s=>Math.round(3+s*20*rnd(.7,1.15)),
 init(o,end){const g={x:W/2,balls:[],t:0,sp:0,lives:3,saves:0,flash:0};
  g.down=g.move=p=>{g.x=Math.max(40,Math.min(W-40,p.x))};
  g.update=dt=>{g.t+=dt;g.sp-=dt;if(g.sp<=0){g.sp=Math.max(.45,1.1-g.saves*.02);const tx=rnd(40,W-40),sx=rnd(60,W-60);g.balls.push({x:sx,y:-10,vx:(tx-sx)/ (560/(230+g.saves*5)),vy:230+g.saves*5})}
   g.balls.forEach(b=>{b.x+=b.vx*dt;b.y+=b.vy*dt});
   g.balls=g.balls.filter(b=>{if(b.y>=560){if(Math.abs(b.x-g.x)<46){g.saves++}else{g.lives--;g.flash=.3}return false}return true});
   g.flash-=dt;if(g.lives<=0)end({score:g.saves,title:'Drei Tore kassiert',sub:g.saves+' Paraden'});if(g.t>60)end({score:g.saves,title:'Zeit um!',sub:g.saves+' Paraden'})};
  g.draw=()=>{const c=C();bg();c.fillStyle=g.flash>0?'rgba(217,41,61,.35)':'rgba(255,255,255,.07)';c.fillRect(0,560,W,6);g.balls.forEach(b=>circle(b.x,b.y,11,'#fff',10));
   bear(g.x,590,26,OR);text('Paraden '+g.saves,100,40,28,'#fff');text('♥'.repeat(Math.max(0,g.lives)),W-60,40,28,'#d9293d')};
  return g}});

reg('ballrain',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(8+s*30*rnd(.7,1.1)),
 init(o,end){const g={x:W/2,t:30,score:0,items:[],sp:0};
  g.down=g.move=p=>{g.x=Math.max(30,Math.min(W-30,p.x))};
  g.update=dt=>{g.t-=dt;g.sp-=dt;if(g.sp<=0){g.sp=rnd(.22,.45);const r=Math.random();g.items.push({x:rnd(20,W-20),y:-10,vy:rnd(150,240),k:r<.15?'gold':r<.4?'card':'ball'})}
   g.items.forEach(i=>i.y+=i.vy*dt);
   g.items=g.items.filter(i=>{if(i.y>580&&i.y<625&&Math.abs(i.x-g.x)<40){g.score+=i.k==='gold'?3:i.k==='card'?-3:1;return false}return i.y<660});
   if(g.t<=0)end({score:g.score,title:'Zeit um!',sub:g.score+' Punkte'})};
  g.draw=()=>{const c=C();bg();g.items.forEach(i=>{if(i.k==='card'){c.fillStyle='#ffd400';c.fillRect(i.x-9,i.y-13,18,26)}else circle(i.x,i.y,i.k==='gold'?13:10,i.k==='gold'?'#ffc400':'#fff',8)});
   bear(g.x,600,28,OR);hudTime(g.t,g.score)};
  return g}});

reg('powershot',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(8*(40+s*55)*rnd(.8,1.05)/ (1)),
 init(o,end){const g={shot:0,score:0,p:0,dir:1,sp:1.2,zone:rnd(.25,.75),msg:'',mt:0,total:8};
  g.down=()=>{if(g.mt>0)return;const d=Math.abs(g.p-g.zone),pts=d<.06?100:Math.max(0,Math.round(90-d*220));g.score+=pts;g.msg=pts>=95?'PERFEKT +'+pts:pts>0?'+'+pts:'Daneben';g.mt=.9;g.shot++;};
  g.update=dt=>{if(g.mt>0){g.mt-=dt;if(g.mt<=0){if(g.shot>=g.total)end({score:g.score,title:'Fertig!',sub:g.score+' Punkte'});else{g.zone=rnd(.2,.8);g.sp=1.1+g.shot*.18}}return}
   g.p+=g.dir*g.sp*dt;if(g.p>1){g.p=1;g.dir=-1}if(g.p<0){g.p=0;g.dir=1}};
  g.draw=()=>{const c=C();bg();c.fillStyle='#243a57';rrect(30,300,300,40,20);c.fill();c.fillStyle='#1fbf5b';c.fillRect(30+g.zone*300-18,300,36,40);c.fillStyle='#fff';c.fillRect(30+g.p*300-4,290,8,60);
   text('Schuss '+Math.min(g.shot+1,g.total)+' / '+g.total,W/2,90,34,OR);text(g.score,W/2,170,70,'#fff');text('Tippen im grünen Bereich',W/2,430,22,BL);if(g.mt>0)text(g.msg,W/2,520,40,'#fff')};
  return g}});

reg('juggle',{best:'hoch',unit:' Kontakte',cpuScore:s=>Math.round(5+s*45*rnd(.6,1.1)),
 init(o,end){const g={x:W/2,y:300,vx:0,vy:0,taps:0,t:45,grav:700};
  g.down=p=>{if(dist(p.x,p.y,g.x,g.y)<62){g.taps++;g.vy=-430-Math.min(150,g.taps*4);g.vx=(g.x-p.x)*6+rnd(-40,40);g.grav=700+g.taps*14}};
  g.update=dt=>{g.t-=dt;g.vy+=g.grav*dt;g.x+=g.vx*dt;g.y+=g.vy*dt;if(g.x<22){g.x=22;g.vx=Math.abs(g.vx)}if(g.x>W-22){g.x=W-22;g.vx=-Math.abs(g.vx)}
   if(g.y>H+30)end({score:g.taps,title:'Fallen gelassen',sub:g.taps+' Kontakte'});if(g.t<=0)end({score:g.taps,title:'Zeit um!',sub:g.taps+' Kontakte'})};
  g.draw=()=>{bg();circle(g.x,g.y,22,'#fff',16);text(g.taps,W/2,90,80,'rgba(255,255,255,.9)');hudTime(g.t)};
  return g}});

reg('quiz',{best:'hoch',unit:' Punkte',cpuScore:s=>{let t=0;for(let i=0;i<6;i++)if(Math.random()<.35+s*.6)t+=3+Math.round(rnd(0,3)*(.4+s));return t},
 init(o,end){const pool=[...QUIZ].sort(()=>Math.random()-.5).slice(0,6);
  const g={i:0,score:0,t:0,limit:12,sel:-1,wait:0,opts:[]};
  const setQ=()=>{const q=pool[g.i];g.q=q[0];g.opts=q[1].map((a,k)=>({a,ok:k===0})).sort(()=>Math.random()-.5);g.t=0;g.sel=-1;g.wait=0};setQ();
  const wrap=(s,max)=>{const w=s.split(' ');const lines=[];let l='';w.forEach(x=>{if((l+' '+x).length>max){lines.push(l);l=x}else l=l?l+' '+x:x});lines.push(l);return lines};
  g.down=p=>{if(g.sel>=0)return;g.opts.forEach((op,k)=>{const y=330+k*72;if(p.x>24&&p.x<W-24&&p.y>y&&p.y<y+60){g.sel=k;if(op.ok)g.score+=3+Math.round(3*Math.max(0,1-g.t/g.limit));g.wait=1}})};
  g.update=dt=>{if(g.sel>=0){g.wait-=dt;if(g.wait<=0){g.i++;if(g.i>=6)end({score:g.score,title:'Quiz beendet',sub:g.score+' Punkte'});else setQ()}return}g.t+=dt;if(g.t>=g.limit){g.sel=9;g.wait=.8}};
  g.draw=()=>{const c=C();bg();text('Frage '+(g.i+1)+' / 6',W/2,40,26,OR);
   c.fillStyle=BL;c.fillRect(24,64,(W-48)*(1-g.t/g.limit),6);
   wrap(g.q,24).forEach((l,k)=>text(l,W/2,120+k*28,22,'#fff'));
   g.opts.forEach((op,k)=>{const y=330+k*72;const show=g.sel>=0;c.fillStyle=show?(op.ok?'#1fbf5b':k===g.sel?'#d9293d':'#243a57'):'#243a57';rrect(24,y,W-48,60,14);c.fill();c.strokeStyle=OR;c.lineWidth=2;c.stroke();
    wrap(op.a,26).slice(0,2).forEach((l,j,ar)=>text(l,W/2,y+30+(j-(ar.length-1)/2)*20,18,'#fff'))});
   text('Punkte '+g.score,W/2,H-24,22,BL)};
  return g}});

reg('duel',{versus:true,maxPlayers:2,
 init(o,end){const names=['Schläger','Ball','Handschuh'],ico=['S','B','H'];
  const g={r:0,w:[0,0],pick:[-1,-1],rev:0,msg:'',cpuT:rnd(.6,1.6)};
  const beats=(a,b)=>(a===0&&b===1)||(a===1&&b===2)||(a===2&&b===0);
  const bx=k=>({x:30+k*100,w:92});
  g.down=p=>{const bottom=p.y>H/2;if(g.rev>0)return;for(let k=0;k<3;k++){const b=bx(k);if(p.x>b.x&&p.x<b.x+b.w&&((bottom&&p.y>460&&p.y<580)||(!bottom&&o.two&&p.y>60&&p.y<180))){if(bottom&&g.pick[0]<0)g.pick[0]=k;if(!bottom&&g.pick[1]<0)g.pick[1]=k}}};
  g.update=dt=>{if(g.rev>0){g.rev-=dt;if(g.rev<=0){if(g.w[0]>=3)end({winner:0,title:'Gewonnen!',sub:g.w[0]+' : '+g.w[1]});else if(g.w[1]>=3)end({winner:1,title:'Verloren',sub:g.w[0]+' : '+g.w[1]});else{g.pick=[-1,-1];g.cpuT=rnd(.6,1.6)}}return}
   if(!o.two&&g.pick[0]>=0&&g.pick[1]<0){g.cpuT-=dt;if(g.cpuT<=0)g.pick[1]=Math.random()<.2+o.skill*.3?(g.pick[0]+1)%3:Math.floor(Math.random()*3)}
   if(g.pick[0]>=0&&g.pick[1]>=0){const a=g.pick[0],b=g.pick[1];if(beats(a,b)){g.w[0]++;g.msg='Punkt unten'}else if(beats(b,a)){g.w[1]++;g.msg='Punkt oben'}else g.msg='Unentschieden';g.rev=1.4}};
  g.draw=()=>{const c=C();bg();c.fillStyle='rgba(56,200,255,.1)';c.fillRect(0,0,W,H/2);c.fillStyle='rgba(255,106,0,.1)';c.fillRect(0,H/2,W,H/2);
   for(let k=0;k<3;k++){const b=bx(k);c.fillStyle='#243a57';rrect(b.x,460,b.w,120,16);c.fill();c.strokeStyle=g.pick[0]===k?'#fff':OR;c.lineWidth=g.pick[0]===k?4:2;c.stroke();c.font='44px system-ui';c.textAlign='center';c.fillStyle='#fff';c.fillText(ico[k],b.x+b.w/2,520);
    if(o.two){c.fillStyle='#243a57';rrect(b.x,60,b.w,120,16);c.fill();c.strokeStyle=g.pick[1]===k?'#fff':BL;c.lineWidth=g.pick[1]===k?4:2;c.stroke();c.save();c.translate(b.x+b.w/2,120);c.rotate(Math.PI);c.fillText(ico[k],0,10);c.restore()}}
   if(g.rev>0){c.font='72px system-ui';c.fillText(ico[g.pick[0]],W/2,420);c.save();c.translate(W/2,220);c.rotate(Math.PI);c.fillText(ico[g.pick[1]],0,0);c.restore();text(g.msg,W/2,H/2,34,'#fff')}
   else text(g.pick[0]<0?'Wähle unten':'Warten …',W/2,H/2,30,'rgba(255,255,255,.7)');
   text(g.w[0],W-24,H/2+40,40,OR);text(g.w[1],W-24,H/2-40,40,BL);text('Erster mit 3 gewinnt',W/2,H-24,18,'rgba(255,255,255,.5)')};
  return g}});

reg('dash',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(40+s*220*rnd(.7,1.1)),
 init(o,end){const lanes=[90,180,270],g={lane:1,x:180,items:[],t:45,sp:0,lives:3,pts:0,dist:0,speed:220,inv:0};
  g.down=p=>{g.lane=Math.max(0,Math.min(2,g.lane+(p.x<W/2?-1:1)))};
  g.update=dt=>{g.t-=dt;g.speed=220+(45-g.t)*4;g.dist+=g.speed*dt;g.x+=(lanes[g.lane]-g.x)*Math.min(1,dt*16);g.inv-=dt;g.sp-=dt;
   if(g.sp<=0){g.sp=rnd(.5,.9)*220/g.speed*1.2;const l=Math.floor(Math.random()*3);g.items.push({l,y:-20,k:Math.random()<.55?'ball':'block'})}
   g.items.forEach(i=>i.y+=g.speed*dt);
   g.items=g.items.filter(i=>{if(i.y>540&&i.y<600&&i.l===g.lane){if(i.k==='ball'){g.pts+=10;return false}if(g.inv<=0){g.lives--;g.inv=1}return false}return i.y<700});
   if(g.lives<=0)end({score:g.pts+Math.floor(g.dist/50),title:'Zusammengestossen',sub:(g.pts+Math.floor(g.dist/50))+' Punkte'});
   if(g.t<=0)end({score:g.pts+Math.floor(g.dist/50),title:'Ziel erreicht',sub:(g.pts+Math.floor(g.dist/50))+' Punkte'})};
  g.draw=()=>{const c=C();bg();c.strokeStyle='rgba(56,200,255,.25)';c.lineWidth=2;[135,225].forEach(x=>{c.setLineDash([14,14]);c.beginPath();c.moveTo(x,0);c.lineTo(x,H);c.stroke()});c.setLineDash([]);
   g.items.forEach(i=>{if(i.k==='ball')circle(lanes[i.l],i.y,12,'#fff',10);else{c.fillStyle='#d9293d';rrect(lanes[i.l]-30,i.y-18,60,36,8);c.fill()}});
   c.globalAlpha=g.inv>0&&Math.floor(g.inv*10)%2?.4:1;bear(g.x,575,26,OR);c.globalAlpha=1;
   hudTime(g.t,g.pts+Math.floor(g.dist/50));text('♥'.repeat(Math.max(0,g.lives)),W/2,38,26,'#d9293d')};
  return g}});

reg('ninja',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(6+s*28*rnd(.7,1.1)),
 init(o,end){const g={t:30,score:0,items:[],sp:0,trail:[],last:null,fx:[]};
  g.down=p=>{g.last=p;g.trail=[p]};g.up=()=>{g.last=null;g.trail=[]};
  g.move=p=>{if(!g.last)return;const a=g.last,b=p;g.trail.push(p);if(g.trail.length>8)g.trail.shift();
   g.items=g.items.filter(i=>{const abx=b.x-a.x,aby=b.y-a.y,l2=abx*abx+aby*aby||1,tt=Math.max(0,Math.min(1,((i.x-a.x)*abx+(i.y-a.y)*aby)/l2)),d=dist(i.x,i.y,a.x+abx*tt,a.y+aby*tt);
    if(d<i.r+6&&l2>16){g.score+=i.bad?-3:1;g.fx.push({x:i.x,y:i.y,t:.3,bad:i.bad});return false}return true});g.last=b};
  g.update=dt=>{g.t-=dt;g.sp-=dt;if(g.sp<=0){g.sp=rnd(.3,.7);const x=rnd(50,W-50);g.items.push({x,y:H+20,vx:(W/2-x)*rnd(.1,.5)+rnd(-40,40),vy:-rnd(560,780),r:24,bad:Math.random()<.2})}
   g.items.forEach(i=>{i.x+=i.vx*dt;i.y+=i.vy*dt;i.vy+=720*dt});g.items=g.items.filter(i=>i.y<H+60);g.fx.forEach(f=>f.t-=dt);g.fx=g.fx.filter(f=>f.t>0);
   if(g.t<=0)end({score:g.score,title:'Zeit um!',sub:g.score+' Punkte'})};
  g.draw=()=>{const c=C();bg();g.items.forEach(i=>{if(i.bad){c.fillStyle='#d9293d';rrect(i.x-14,i.y-20,28,40,5);c.fill()}else circle(i.x,i.y,i.r,'#fff',12)});
   g.fx.forEach(f=>{c.globalAlpha=f.t/.3;circle(f.x,f.y,60*(1-f.t/.3)+16,f.bad?'#d9293d':OR);c.globalAlpha=1});
   if(g.trail.length>1){c.strokeStyle=BL;c.lineWidth=6;c.lineCap='round';c.beginPath();g.trail.forEach((p,k)=>k?c.lineTo(p.x,p.y):c.moveTo(p.x,p.y));c.stroke()}hudTime(g.t,g.score)};
  return g}});

reg('stack',{best:'hoch',unit:' Stockwerke',cpuScore:s=>Math.round(3+s*14*rnd(.6,1.1)),
 init(o,end){const g={blocks:[{x:W/2,w:150}],x:0,w:150,dir:1,sp:150,h:0,fall:null,cam:0};
  g.down=()=>{const top=g.blocks[g.blocks.length-1],l=Math.max(g.x-g.w/2,top.x-top.w/2),r=Math.min(g.x+g.w/2,top.x+top.w/2),ov=r-l;
   if(ov<=0){end({score:g.h,title:'Daneben!',sub:g.h+' Stockwerke'});return}
   const nw=Math.abs(ov-g.w)<5?g.w:ov;g.blocks.push({x:(l+r)/2,w:nw});g.w=nw;g.h++;g.sp=150+g.h*9;g.x=g.dir>0?0:W};
  g.update=dt=>{g.x+=g.dir*g.sp*dt;if(g.x>W-g.w/2){g.x=W-g.w/2;g.dir=-1}if(g.x<g.w/2){g.x=g.w/2;g.dir=1}g.cam+=((g.blocks.length)*30-g.cam)*Math.min(1,dt*4)};
  g.draw=()=>{const c=C();bg();const base=560+Math.max(0,g.cam-300);g.blocks.forEach((b,k)=>{c.fillStyle=k%2?OR:'#ff9a4d';c.fillRect(b.x-b.w/2,base-(k+1)*30+ (0),b.w,28)});
   c.fillStyle=BL;c.fillRect(g.x-g.w/2,Math.max(120,base-(g.blocks.length+1)*30),g.w,28);text(g.h,W/2,60,56,'#fff')};
  return g}});
})();
