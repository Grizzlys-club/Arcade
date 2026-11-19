/* Batch 4: Sortierer, Ausweichen, Höhle, Pendel, Zähler, Rutsch, Schneeball, Zickzack, Lichter aus + überarbeitete Klassiker */
(()=>{
'use strict';
const {W,H,OR,BL,rnd,text,circle,bg,bear,rrect}=GA,C=()=>GA.c,G=GAMES;
const reg=(id,o)=>{G[id]=Object.assign({name:NAMES[id],sub:'ca. '+SECS[id]+' Sekunden',help:RULES[id],tag:TAGS[id]},o)};
const dist=(a,b,c,d)=>Math.hypot(a-c,b-d);
const now=()=>performance.now();
function hudTime(t,s){text(Math.ceil(Math.max(0,t)),W-34,38,36,BL);if(s!=null)text(s,34,38,36,'#fff')}
const COL=['#d9293d','#38c8ff'];

reg('sorter',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(8+s*30*rnd(.6,1.1)),
 init(o,end){const g={t:30,score:0,balls:[],sp:0,a:null,fx:0,ok:true};
  g.down=p=>{g.a=p};g.up=p=>{if(!g.a)return;const dx=p.x-g.a.x;g.a=null;if(Math.abs(dx)<30)return;const side=dx<0?0:1;const b=g.balls[0];if(!b)return;g.ok=b.c===side;g.score+=g.ok?1:-1;g.fx=.3;g.balls.shift()};
  g.update=dt=>{g.t-=dt;g.sp-=dt;if(g.sp<=0){g.sp=1.0;g.balls.push({c:Math.floor(Math.random()*2),y:-20,x:W/2})}g.balls.forEach((b,i)=>b.y+=(150+g.score*4)*dt);
   if(g.balls.length&&g.balls[0].y>480){g.score-=1;g.ok=false;g.fx=.3;g.balls.shift()}g.fx-=dt;g.balls.sort((a,b)=>b.y-a.y);if(g.t<=0)end({score:g.score,title:'Zeit um!',sub:g.score+' Punkte'})};
  g.draw=()=>{const c=C();bg();c.fillStyle=COL[0];rrect(10,500,150,110,16);c.fill();c.fillStyle=COL[1];rrect(200,500,150,110,16);c.fill();text('←',85,555,52,'#111');text('→',275,555,52,'#111');
   g.balls.forEach(b=>circle(b.x,b.y,22,COL[b.c],14));if(g.fx>0)text(g.ok?'+1':'−1',W/2,330,44,g.ok?'#1fbf5b':'#d9293d');hudTime(g.t,g.score)};
  return g}});

reg('dodge',{best:'hoch',unit:' s',cpuScore:s=>Math.round((8+s*35*rnd(.6,1.1))*10)/10,
 init(o,end){const g={x:W/2,tx:W/2,t:0,pucks:[],sp:0};
  g.down=g.move=p=>{g.tx=p.x};
  g.update=dt=>{g.t+=dt;g.x+=(g.tx-g.x)*Math.min(1,dt*14);g.sp-=dt;if(g.sp<=0){g.sp=Math.max(.14,.55-g.t*.01);g.pucks.push({x:rnd(14,W-14),y:-14,vy:rnd(220,330)+g.t*4})}
   g.pucks.forEach(p=>p.y+=p.vy*dt);g.pucks=g.pucks.filter(p=>p.y<H+20);
   if(g.pucks.some(p=>dist(p.x,p.y,g.x,590)<26))end({score:Math.round(g.t*10)/10,title:'Getroffen!',sub:g.t.toFixed(1)+' Sekunden überlebt'});if(g.t>90)end({score:90,title:'Unverwundbar!',sub:'90 Sekunden'})};
  g.draw=()=>{bg();g.pucks.forEach(p=>circle(p.x,p.y,11,'#fff',8));bear(g.x,596,22,OR);text(g.t.toFixed(1)+' s',W/2,44,44,'#fff')};
  return g}});

reg('cave',{best:'hoch',unit:' m',cpuScore:s=>Math.round(40+s*140*rnd(.6,1.1)),
 init(o,end){const g={y:320,vy:0,hold:false,dist:0,cols:[],cx:0,t:0};
  const gap=()=>Math.max(150,260-g.dist/60);let ctr=320;for(let i=0;i<40;i++){g.cols.push({c:ctr,g:260});}
  g.down=()=>{g.hold=true};g.up=()=>{g.hold=false};
  g.update=dt=>{g.t+=dt;const spd=160+g.dist/40;g.dist+=spd*dt;g.cx+=spd*dt;g.vy+=(g.hold?-1000:900)*dt;g.vy=Math.max(-380,Math.min(380,g.vy));g.y+=g.vy*dt;
   while(g.cx>=10){g.cx-=10;ctr+=rnd(-24,24);ctr=Math.max(190,Math.min(H-190,ctr));g.cols.shift();g.cols.push({c:ctr,g:gap()})}
   const col=g.cols[8];if(g.y<col.c-col.g/2+14||g.y>col.c+col.g/2-14||g.y<0||g.y>H)end({score:Math.round(g.dist/10),title:'Gegen die Wand!',sub:Math.round(g.dist/10)+' m'})};
  g.draw=()=>{const c=C();bg();c.fillStyle='#7fd8ff';g.cols.forEach((k,i)=>{const x=i*10-g.cx;c.fillRect(x,0,10.5,k.c-k.g/2);c.fillRect(x,k.c+k.g/2,10.5,H)});
   bear(g.cols.length?80:80,g.y,14,OR);text(Math.round(g.dist/10)+' m',W/2,50,44,'#fff');text('Halten = steigen',W/2,H-24,20,BL)};
  return g}});

reg('pendulum',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(8+s*20*rnd(.6,1.1)),
 init(o,end){const g={n:0,score:0,a:0,t:0,ball:null,tx:rnd(80,W-80),msg:'',mt:0,total:6};const px=W/2,py=60,L=250;
  g.down=()=>{if(g.ball||g.mt>0)return;const ang=Math.sin(g.t*2.2)*1.0,bx=px+Math.sin(ang)*L,by=py+Math.cos(ang)*L,vang=Math.cos(g.t*2.2)*2.2*1.0;g.ball={x:bx,y:by,vx:Math.cos(ang)*vang*L,vy:-Math.sin(ang)*vang*L-320}};
  g.update=dt=>{g.t+=dt*(1+g.n*.08);if(g.ball){const b=g.ball;b.x+=b.vx*dt;b.y+=b.vy*dt;b.vy+=800*dt;if(b.y>540&&b.vy>0){const d=Math.abs(b.x-g.tx);const pts=d<18?10:d<45?5:d<80?2:0;g.score+=pts;g.msg=pts?'+'+pts:'Daneben';g.mt=.9;g.n++;g.ball=null;g.tx=rnd(70,W-70)}}
   if(g.mt>0){g.mt-=dt;if(g.mt<=0&&g.n>=g.total)end({score:g.score,title:g.score+' Punkte',sub:'6 Würfe'})}};
  g.draw=()=>{const c=C();bg();const ang=Math.sin(g.t*2.2)*1.0,bx=px+Math.sin(ang)*L,by=py+Math.cos(ang)*L;c.strokeStyle='#fff';c.lineWidth=3;if(!g.ball){c.beginPath();c.moveTo(px,py);c.lineTo(bx,by);c.stroke();circle(bx,by,16,OR,12)}else circle(g.ball.x,g.ball.y,16,OR,12);circle(px,py,6,'#fff');
   [[80,'#d9293d'],[45,'#fff'],[18,'#1fbf5b']].forEach(([r,col])=>{c.fillStyle=col;c.fillRect(g.tx-r,548,r*2,10)});text('Wurf '+Math.min(g.n+1,g.total)+' / '+g.total,W/2,H-60,26,OR);text(g.score,W-40,40,36,'#fff');if(g.mt>0)text(g.msg,W/2,420,34,'#fff')};
  return g}});

reg('count',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(8+s*30*rnd(.6,1.1)),
 init(o,end){const g={r:0,score:0,state:'show',t:0,n:0,pucks:[],sel:-1,opts:[],tt:0};
  const mk=()=>{g.n=Math.floor(rnd(3,6+g.r));g.pucks=[];for(let i=0;i<g.n;i++)g.pucks.push({x:rnd(40,W-40),y:rnd(120,430)});g.state='show';g.t=1.0;const s=new Set([g.n]);while(s.size<4){const v=g.n+Math.floor(rnd(-2,3));if(v>0)s.add(v)}g.opts=[...s].sort((a,b)=>a-b);g.sel=-1;g.tt=0};mk();
  g.down=p=>{if(g.state!=='ask'||g.sel>=0)return;g.opts.forEach((v,k)=>{const x=20+(k%2)*165,y=470+Math.floor(k/2)*76;if(p.x>x&&p.x<x+155&&p.y>y&&p.y<y+66){g.sel=k;if(v===g.n)g.score+=5+Math.max(0,Math.round(4-g.tt));g.t=.8}})};
  g.update=dt=>{g.t-=dt;if(g.state==='show'&&g.t<=0){g.state='ask';g.tt=0;g.t=99}else if(g.state==='ask'){g.tt+=dt;if(g.sel>=0){g.t-=dt-0;if(g.t<=99-0){}}}
   if(g.state==='ask'&&g.sel>=0){g.hold=(g.hold||0)+dt;if(g.hold>.8){g.hold=0;g.r++;if(g.r>=8)end({score:g.score,title:'Geschafft!',sub:g.score+' Punkte'});else mk()}}};
  g.draw=()=>{const c=C();bg();text('Runde '+(g.r+1)+' / 8',W/2,40,26,OR);if(g.state==='show'){g.pucks.forEach(p=>circle(p.x,p.y,14,'#fff',12));text('Wie viele?',W/2,520,30,BL)}else{text('Wie viele Pucks waren es?',W/2,200,26,'#fff');g.opts.forEach((v,k)=>{const x=20+(k%2)*165,y=470+Math.floor(k/2)*76;c.fillStyle=g.sel>=0?(v===g.n?'#1fbf5b':k===g.sel?'#d9293d':'#243a57'):'#243a57';rrect(x,y,155,66,16);c.fill();c.strokeStyle=OR;c.lineWidth=2;c.stroke();text(v,x+77,y+33,38,'#fff')})}text(g.score+' Punkte',W/2,H-24,22,'#fff')};
  return g}});

reg('slide',{best:'hoch',unit:' Level',cpuScore:s=>Math.round(2+s*9*rnd(.6,1.1)),
 init(o,end){const N=6,g={t:50,lvl:0,x:0,y:0,grid:[],gx:0,gy:0,a:null,moving:null};
  const dirs={u:[0,-1],d:[0,1],l:[-1,0],r:[1,0]};
  const slideFrom=(grid,x,y,d)=>{let [dx,dy]=dirs[d],cx=x,cy=y;for(;;){const nx=cx+dx,ny=cy+dy;if(nx<0||ny<0||nx>=N||ny>=N||grid[ny][nx]==='W')return{x:cx,y:cy,hole:false};if(grid[ny][nx]==='H')return{x:nx,y:ny,hole:true};cx=nx;cy=ny;if(grid[cy][cx]==='G')return{x:cx,y:cy,hole:false,goal:true}}};
  const solvable=(grid,sx,sy)=>{const seen=new Set([sx+','+sy]),q=[[sx,sy,0]];while(q.length){const [x,y,d]=q.shift();for(const k of 'udlr'){const r=slideFrom(grid,x,y,k);if(r.hole)continue;if(r.goal)return d+1;const key=r.x+','+r.y;if(!seen.has(key)){seen.add(key);q.push([r.x,r.y,d+1])}}}return 0};
  const mk=()=>{for(let tries=0;tries<400;tries++){const gr=[];for(let y=0;y<N;y++){gr.push([]);for(let x=0;x<N;x++){const r=Math.random();gr[y].push(r<.16?'W':r<.24?'H':'.')}}const sx=Math.floor(Math.random()*N),sy=N-1;const gx=Math.floor(Math.random()*N),gy=0;gr[sy][sx]='.';gr[gy][gx]='G';const d=solvable(gr,sx,sy);if(d>=3&&d<=7){g.grid=gr;g.x=sx;g.y=sy;g.gx=gx;g.gy=gy;return}}
   g.grid=[];for(let y=0;y<N;y++){g.grid.push([]);for(let x=0;x<N;x++)g.grid[y].push('.')}g.grid[0][2]='G';g.x=2;g.y=5};mk();
  g.down=p=>{g.a=p};g.up=p=>{if(!g.a||g.moving)return;const dx=p.x-g.a.x,dy=p.y-g.a.y;g.a=null;if(Math.hypot(dx,dy)<30)return;const d=Math.abs(dx)>Math.abs(dy)?(dx>0?'r':'l'):(dy>0?'d':'u');const r=slideFrom(g.grid,g.x,g.y,d);g.moving={r,t:0,sx:g.x,sy:g.y}};
  const S=(W-40)/N;
  g.update=dt=>{g.t-=dt;if(g.moving){g.moving.t+=dt*5;if(g.moving.t>=1){const r=g.moving.r;g.moving=null;if(r.hole){mk()}else{g.x=r.x;g.y=r.y;if(r.goal){g.lvl++;mk()}}}}if(g.t<=0)end({score:g.lvl,title:'Zeit um!',sub:g.lvl+' Level geschafft'})};
  g.draw=()=>{const c=C();bg();for(let y=0;y<N;y++)for(let x=0;x<N;x++){const v=g.grid[y][x],px=20+x*S,py=130+y*S;c.fillStyle=v==='W'?'#556b84':'#16304d';rrect(px+2,py+2,S-4,S-4,10);c.fill();if(v==='H')circle(px+S/2,py+S/2,S*.3,'#000');if(v==='G'){c.font='34px system-ui';c.textAlign='center';c.textBaseline='middle';c.fillStyle='#fff';c.fillText('🏆',px+S/2,py+S/2)}}
   let bx=g.x,by=g.y;if(g.moving){const m=g.moving,k=Math.min(1,m.t);bx=m.sx+(m.r.x-m.sx)*k;by=m.sy+(m.r.y-m.sy)*k}bear(20+bx*S+S/2,130+by*S+S/2,S*.32,OR);hudTime(g.t,g.lvl);text('Wische, bis der Bär anstösst',W/2,H-30,20,BL)};
  return g}});

reg('snowball',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(5+s*20*rnd(.6,1.1)),
 init(o,end){const g={t:30,score:0,tg:[],sp:0,balls:[],a:null,fx:[]};
  g.down=p=>{g.a={x:p.x,y:p.y}};g.up=p=>{if(!g.a)return;const dx=p.x-g.a.x,dy=p.y-g.a.y;g.a=null;if(dy>-25&&Math.hypot(dx,dy)<30)return;const l=Math.hypot(dx,dy)||1;g.balls.push({x:W/2,y:590,vx:dx/l*620,vy:dy/l*620,t:0})};
  g.update=dt=>{g.t-=dt;g.sp-=dt;if(g.sp<=0){g.sp=rnd(.5,1);g.tg.push({x:rnd(50,W-50),y:rnd(120,380),life:2.2,friend:Math.random()<.25})}
   g.tg.forEach(t=>t.life-=dt);g.tg=g.tg.filter(t=>t.life>0);
   g.balls.forEach(b=>{b.x+=b.vx*dt;b.y+=b.vy*dt;b.t+=dt;g.tg=g.tg.filter(t=>{if(dist(b.x,b.y,t.x,t.y)<30){g.score+=t.friend?-3:2;g.fx.push({x:t.x,y:t.y,t:.3,bad:t.friend});b.t=9;return false}return true})});g.balls=g.balls.filter(b=>b.t<2&&b.y>-20&&b.x>-20&&b.x<W+20);
   g.fx.forEach(f=>f.t-=dt);g.fx=g.fx.filter(f=>f.t>0);if(g.t<=0)end({score:g.score,title:'Zeit um!',sub:g.score+' Punkte'})};
  g.draw=()=>{const c=C();bg();g.tg.forEach(t=>{circle(t.x,t.y,26,t.friend?'#1fbf5b':'#d9293d');c.fillStyle='#fff';circle(t.x,t.y,16,'#fff');circle(t.x,t.y,7,t.friend?'#1fbf5b':'#d9293d');if(t.friend)text('Freund',t.x,t.y+40,16,'#1fbf5b')});
   g.balls.forEach(b=>circle(b.x,b.y,9,'#fff',10));g.fx.forEach(f=>{c.globalAlpha=f.t/.3;circle(f.x,f.y,50*(1-f.t/.3)+14,f.bad?'#d9293d':OR);c.globalAlpha=1});bear(W/2,606,24,OR);hudTime(g.t,g.score);text('Zielen & wischen',W/2,H-6,14,BL)};
  return g}});

reg('zigzag',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(20+s*100*rnd(.6,1.1)),
 init(o,end){const g={x:W/2,dir:1,y:0,pts:0,pucks:[],cam:0,sp:200,path:[{x:W/2,y:0}],t:0};
  let px=W/2,py=0,pd=1;for(let i=0;i<200;i++){const len=rnd(50,110);px+=pd*len*.9;py+=len;if(px<70){px=70;pd=1}else if(px>W-70){px=W-70;pd=-1}else if(Math.random()<.55)pd=-pd;g.path.push({x:px,y:py});if(i%3===1)g.pucks.push({x:px,y:py,got:false})}
  g.down=()=>{g.dir=-g.dir};
  const pathX=y=>{for(let i=0;i<g.path.length-1;i++){const a=g.path[i],b=g.path[i+1];if(y>=a.y&&y<=b.y)return a.x+(b.x-a.x)*(y-a.y)/(b.y-a.y)}return g.path[g.path.length-1].x};
  g.update=dt=>{g.t+=dt;g.sp=200+g.t*3;g.y+=g.sp*dt;g.x+=g.dir*g.sp*dt*.9*1;
   const tx=pathX(g.y);if(Math.abs(g.x-tx)>34)end({score:g.pts+Math.floor(g.y/20),title:'Von der Bahn!',sub:(g.pts+Math.floor(g.y/20))+' Punkte'});
   g.pucks.forEach(p=>{if(!p.got&&Math.abs(p.y-g.y)<22&&Math.abs(p.x-g.x)<26){p.got=true;g.pts+=5}});g.cam=g.y-480;if(g.y>g.path[g.path.length-1].y-50)end({score:g.pts+Math.floor(g.y/20),title:'Ziel!',sub:(g.pts+Math.floor(g.y/20))+' Punkte'})};
  g.draw=()=>{const c=C();bg();c.strokeStyle='#7fd8ff';c.lineWidth=68;c.lineJoin='round';c.globalAlpha=.35;c.beginPath();g.path.forEach((p,i)=>{const y=p.y-g.cam;i?c.lineTo(p.x,y):c.moveTo(p.x,y)});c.stroke();c.globalAlpha=1;
   g.pucks.forEach(p=>{if(!p.got)circle(p.x,p.y-g.cam,9,'#fff',8)});bear(g.x,g.y-g.cam,16,OR);text(g.pts+Math.floor(g.y/20),W/2,50,44,'#fff');text('Tippen = Richtung wechseln',W/2,H-24,20,BL)};
  return g}});

reg('lightsout',{best:'tief',unit:' s',cpuScore:s=>Math.round((50-s*35+rnd(-4,4))*10)/10,
 init(o,end){const N=5,g={t:0,cells:[],moves:0};for(let i=0;i<N*N;i++)g.cells.push(false);
  const tog=(x,y)=>{[[0,0],[1,0],[-1,0],[0,1],[0,-1]].forEach(([dx,dy])=>{const nx=x+dx,ny=y+dy;if(nx>=0&&ny>=0&&nx<N&&ny<N)g.cells[ny*N+nx]=!g.cells[ny*N+nx]})};
  for(let i=0;i<9+Math.floor(Math.random()*4);i++)tog(Math.floor(Math.random()*N),Math.floor(Math.random()*N));if(g.cells.every(v=>!v))tog(2,2);
  const S=(W-40)/N;
  g.down=p=>{const x=Math.floor((p.x-20)/S),y=Math.floor((p.y-150)/S);if(x<0||y<0||x>=N||y>=N)return;tog(x,y);g.moves++;if(g.cells.every(v=>!v))end({score:Math.round(g.t*10)/10,title:g.t.toFixed(1)+' s',sub:g.moves+' Züge'})};
  g.update=dt=>{g.t+=dt;if(g.t>120)end({score:120,title:'Zeit um',sub:'120 Sekunden'})};
  g.draw=()=>{const c=C();bg();g.cells.forEach((v,i)=>{const x=20+(i%N)*S,y=150+Math.floor(i/N)*S;c.fillStyle=v?'#ffc400':'#16304d';rrect(x+3,y+3,S-6,S-6,12);c.fill();if(v){c.shadowColor='#ffc400';c.shadowBlur=14;c.fill();c.shadowBlur=0}});text(g.t.toFixed(1)+' s',W/2,60,44,'#fff');text('Alle Lichter ausschalten',W/2,110,22,BL);text(g.moves+' Züge',W/2,H-40,22,OR)};
  return g}});

/* ---- Überarbeitete Klassiker nach den Regeln der App ---- */
reg('stoptime',{best:'tief',unit:' s daneben',cpuScore:s=>Math.round((2.5-s*2.6)*rnd(.5,1.4)*100)/100,
 init(o,end){const targets=[3,4,5,6,7],g={r:0,t:0,run:false,tot:0,msg:'',mt:0,tg:targets[0]};
  g.down=()=>{if(g.mt>0)return;if(!g.run){g.run=true;g.t=0;return}const d=Math.abs(g.t-g.tg);g.tot+=d;g.msg=g.t.toFixed(2)+' s (±'+d.toFixed(2)+')';g.mt=1.2;g.run=false};
  g.update=dt=>{if(g.run)g.t+=dt;if(g.mt>0){g.mt-=dt;if(g.mt<=0){g.r++;if(g.r>=5)end({score:Math.round(g.tot*100)/100,title:g.tot.toFixed(2)+' s',sub:'Summe der Abweichungen'});else{g.tg=targets[g.r];g.t=0}}}};
  g.draw=()=>{bg();text('Runde '+(g.r+1)+' / 5',W/2,60,28,OR);text('Ziel '+g.tg.toFixed(2)+' s',W/2,150,44,'#fff');const show=g.run&&g.t<1.5;text(g.mt>0?g.msg:(g.run?(show?g.t.toFixed(2):'?.??'):'0.00'),W/2,H/2,g.mt>0?38:92,'#fff');text(g.run?'Tippen zum Stoppen':'Tippen zum Starten',W/2,H-130,26,BL);text('Summe '+g.tot.toFixed(2),W/2,H-60,22,'rgba(255,255,255,.7)')};
  return g}});

reg('reflex',{best:'tief',unit:' ms',cpuScore:s=>Math.round(520-s*300+rnd(-30,30)),
 init(o,end){const g={r:0,s:'idle',t:0,ms:0,list:[],msg:'',mt:0,down:false};
  g.down=()=>{if(g.mt>0)return;if(g.s==='idle'){g.s='hold';g.t=rnd(1.2,3.5)}};
  g.up=()=>{if(g.mt>0)return;if(g.s==='hold'){g.list.push(900);g.msg='Zu früh!';g.mt=1;g.s='idle'}else if(g.s==='lit'){const ms=Math.round(g.ms*1000);g.list.push(ms);g.msg=ms+' ms';g.mt=1;g.s='idle'}};
  g.update=dt=>{if(g.mt>0){g.mt-=dt;if(g.mt<=0){g.r++;if(g.r>=5){const a=Math.round(g.list.reduce((x,y)=>x+y,0)/5);end({score:a,title:a+' ms',sub:'Durchschnitt über 5 Runden'})}}return}
   if(g.s==='hold'){g.t-=dt;if(g.t<=0){g.s='lit';g.ms=0}}else if(g.s==='lit')g.ms+=dt};
  g.draw=()=>{const c=C();bg();circle(W/2,H/2,110,g.s==='lit'?'#1fbf5b':g.s==='hold'?'#d9293d':'#243a57',g.s==='lit'?40:0);text(g.mt>0?g.msg:g.s==='idle'?'Finger halten':g.s==='hold'?'Warten …':'LOSLASSEN!',W/2,H/2,g.s==='lit'?34:30,'#fff');text('Runde '+Math.min(g.r+1,5)+' / 5',W/2,60,28,OR)};
  return g}});

reg('whack',{best:'hoch',unit:' Punkte',cpuScore:s=>Math.round(6+s*30*rnd(.7,1.1)),
 init(o,end){const holes=[];for(let r=0;r<4;r++)for(let c=0;c<3;c++)holes.push({x:60+c*120,y:150+r*110,item:null});
  const g={t:30,score:0,sp:0,fx:[]};
  g.down=p=>{holes.forEach(h=>{if(h.item&&dist(p.x,p.y,h.x,h.y-10)<46){g.score+=h.item.ref?-3:1;g.fx.push({x:h.x,y:h.y,t:.35,bad:h.item.ref});h.item=null}})};
  g.update=dt=>{g.t-=dt;g.sp-=dt;if(g.sp<=0){g.sp=rnd(.3,.65);const e=holes.filter(h=>!h.item);if(e.length){const h=e[Math.floor(Math.random()*e.length)];h.item={life:rnd(.8,1.3),ref:Math.random()<.2}}}
   holes.forEach(h=>{if(h.item){h.item.life-=dt;if(h.item.life<=0)h.item=null}});g.fx.forEach(f=>f.t-=dt);g.fx=g.fx.filter(f=>f.t>0);if(g.t<=0)end({score:g.score,title:'Zeit um!',sub:g.score+' Punkte'})};
  g.draw=()=>{const c=C();bg();holes.forEach(h=>{c.fillStyle='#000';c.beginPath();c.ellipse(h.x,h.y+14,44,16,0,0,7);c.fill();if(h.item){if(h.item.ref){c.fillStyle='#ffd400';c.fillRect(h.x-12,h.y-34,24,34)}else circle(h.x,h.y-8,24,OR,12)}});
   g.fx.forEach(f=>{c.globalAlpha=f.t/.35;circle(f.x,f.y,50*(1-f.t/.35)+14,f.bad?'#d9293d':'#fff');c.globalAlpha=1});hudTime(g.t,g.score);text('Gelbe Karte nicht berühren',W/2,H-24,18,'#ffd400')};
  return g}});

/* Tauziehen: beste von 3 */
(()=>{const old=G.tugwar.init;G.tugwar.help=RULES.tugwar;G.tugwar.init=(o,end)=>{const w=[0,0];let inner=null;const make=()=>{inner=old(o,r=>{w[r.winner]++;if(w[0]>=2||w[1]>=2||w[0]+w[1]>=3)end({winner:w[0]>w[1]?0:1,title:w[0]>w[1]?'Gewonnen!':'Verloren',sub:'Runden '+w[0]+' : '+w[1]});else setTimeout(()=>{Object.assign(g,make())},400)});return inner};
   const g={};Object.assign(g,make());const od=g.draw;g.draw=()=>{inner.draw();text('Runden '+w[0]+' : '+w[1],W-60,H/2,18,'#fff')};
   g.down=p=>inner.down(p);g.update=dt=>inner.update(dt);return g}})();
})();
