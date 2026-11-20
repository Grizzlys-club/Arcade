(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const rr=(a,b)=>a+Math.random()*(b-a);
const BR=9,PT=10,PD=22,BASE=250,CAP=620,EDGES=['bottom','top','left','right'];
const NIN={bottom:{x:0,y:1},top:{x:0,y:-1},left:{x:1,y:0},right:{x:-1,y:0}};
class PongGame extends MiniScene{
 static get layout(){return 'arena'}
 static get stripThickness(){return 66}
 perp(e,p){const F=this.F;return e==='bottom'?p.y-F.y:e==='top'?F.t-p.y:e==='left'?p.x-F.x:F.r-p.x}
 setupGame(){this.duration=75;const a=this.arena,F=this.F={x:a.x+3,y:a.y+3,w:a.w-6,h:a.h-6};F.r=F.x+F.w;F.t=F.y+F.h;F.cx=F.x+F.w/2;F.cy=F.y+F.h/2;
  this.paddles=[];this.balls=[];this.edgeNodes={};this.edgeSeat={};this.outCount=0;this.secondBallDone=false;this.suddenDeath=false;this.sdFactor=1;this.humanOutTimer=0;this.bounceCool=0;
  const fw=Math.floor(F.w),fh=Math.floor(F.h);
  const court=new Sprite(Gfx.texture('pong_court_'+fw+'x'+fh,fw,fh,1.5,c=>{Gfx.gradientColors(c,rgba(.04,.09,.1),rgba(.02,.04,.07),fw,fh);c.strokeStyle='rgba(102,255,153,.07)';c.lineWidth=1;c.beginPath();for(let x=0;x<=fw;x+=32){c.moveTo(x,0);c.lineTo(x,fh)}for(let y=0;y<=fh;y+=32){c.moveTo(0,y);c.lineTo(fw,y)}c.stroke();
   c.strokeStyle='rgba(128,255,179,.28)';c.lineWidth=2;c.beginPath();c.arc(fw/2,fh/2,50,0,7);c.stroke();c.setLineDash([8,8]);c.beginPath();c.moveTo(0,fh/2);c.lineTo(fw,fh/2);c.moveTo(fw/2,0);c.lineTo(fw/2,fh);c.stroke()}),F.w,F.h);
  court.x=F.cx;court.y=F.cy;court.z=-20;this.world.add(court);
  const ld=Math.min(F.w,F.h)*.5,logo=new Sprite(Gfx.logo,ld,ld);logo.x=F.cx;logo.y=F.cy;logo.alpha=.08;logo.z=-19;this.world.add(logo);
  for(const s of this.seats)this.edgeSeat[s.edge]=s.index;
  for(const e of EDGES){const horiz=e==='bottom'||e==='top',sw=horiz?F.w:5,sh=horiz?5:F.h,col=this.edgeSeat[e]!==undefined?this.seats[this.edgeSeat[e]].color:white(.85);
   const node=new Sprite(Gfx.pill(sw,sh,col,null,2.5,false),sw,sh);if(e==='bottom'){node.x=F.cx;node.y=F.y}else if(e==='top'){node.x=F.cx;node.y=F.t}else if(e==='left'){node.x=F.x;node.y=F.cy}else{node.x=F.r;node.y=F.cy}
   node.z=-8;node.alpha=this.edgeSeat[e]===undefined?.6:1;this.world.add(node);
   const gl=new Sprite(Gfx.glow(),horiz?sw*1.05:46,horiz?46:sh*1.05);gl.color=col;gl.cbf=1;gl.blend='add';gl.alpha=this.edgeSeat[e]===undefined?.25:.5;node.add(gl);node.glow=gl;this.edgeNodes[e]=node}
  for(const s of this.seats){const p={edge:s.edge,nin:NIN[s.edge],horizontal:s.edge==='bottom'||s.edge==='top',vel:0,lives:3,saves:0,outOrder:-1,hearts:[],think:0,aimOff:0,wasApproaching:false,touch:null,running:false,node:new Node()};
   if(s.edge==='bottom')p.line={x:F.cx,y:F.y};else if(s.edge==='top')p.line={x:F.cx,y:F.t};else if(s.edge==='left')p.line={x:F.x,y:F.cy};else p.line={x:F.r,y:F.cy};
   p.latMin=p.horizontal?F.x:F.y;p.latMax=p.horizontal?F.r:F.t;const el=p.latMax-p.latMin;p.len=p.horizontal?Math.min(104,el*.28):Math.min(92,el*.15);p.u=(p.latMin+p.latMax)/2;p.target=p.u;
   const node=p.node;node.rot=s.rotation;const handle=new Sprite(null,5,PD+12-PT/2,white(.9));handle.y=-(PD+12+PT/2)/2;handle.z=-1;node.add(handle);
   const glow=new Sprite(Gfx.glow(),p.len+40,PT+40);glow.color=s.color;glow.cbf=1;glow.blend='add';glow.alpha=.6;node.add(glow);p.glow=glow;
   const bar=new Sprite(Gfx.pill(p.len,PT,s.color,'#fff',5,false),p.len,PT);bar.z=1;node.add(bar);p.bar=bar;node.z=30;this.world.add(node);
   const bh=p.horizontal?36:28,bear=this.makeBear(s,bh,s.index%2===0);bear.rot=s.rotation;bear.z=28;this.world.add(bear);p.bear=bear;
   for(let i=0;i<3;i++){const h=label('♥',17,s.color);h.x=-s.w/2+20+i*19;h.y=-s.h/2+13;h.z=410;s.node.add(h);p.hearts.push(h)}
   if(!s.isCPU){const hint=label('← WISCHEN →',12,white(1,.7));hint.x=38;hint.y=-s.h/2+13;hint.z=410;s.node.add(hint);hint.run(A.sequence([A.wait(6),A.fadeOut(.5),A.remove()]))}
   this.paddles.push(p);this.place(p)}
  for(let i=0;i<2;i++)this.balls.push(this.makeBall());this.balls[0].timer=.3;this.balls[1].timer=9999}
 makeBall(){const b={node:new Node(),pos:{x:0,y:0},vel:{x:0,y:0},spin:0,speed:BASE,active:false,timer:.5,last:-1,trail:[],trailAge:[],trailIdx:0,trailT:0};
  const g=new Sprite(Gfx.glow(),BR*5,BR*5);g.color='#fff';g.cbf=1;g.blend='add';g.alpha=.7;b.node.add(g);b.glow=g;
  const body=new Sprite(Gfx.circle(BR,white(.97),Theme.orange),BR*2,BR*2);body.z=1;b.node.add(body);b.body=body;b.node.z=25;b.node.hidden=true;this.world.add(b.node);
  for(let i=0;i<14;i++){const t=new Sprite(Gfx.glow(),BR*2.6,BR*2.6);t.color='#fff';t.cbf=1;t.blend='add';t.alpha=0;t.z=20;this.world.add(t);b.trail.push(t);b.trailAge.push(9)}return b}
 place(p){if(p.horizontal){p.node.x=p.u;p.node.y=p.line.y+p.nin.y*PD}else{p.node.x=p.line.x+p.nin.x*PD;p.node.y=p.u}const bh=p.bear.height;
  if(p.horizontal){p.bear.x=p.u;p.bear.y=p.line.y-p.nin.y*(bh+5)}else{p.bear.x=p.line.x-p.nin.x*(bh+5);p.bear.y=p.u}}
 began(seat,at,id){const p=this.paddles[seat.index];p.touch=id;this.setTarget(seat,p,at)}
 moved(seat,at,id){const p=this.paddles[seat.index];if(p.touch===null)p.touch=id;if(p.touch===id)this.setTarget(seat,p,at)}
 ended(seat,at,id){const p=this.paddles[seat.index];if(p.touch===id)p.touch=null}
 setTarget(seat,p,at){const sp=seat.toScene(at);p.target=this.clampU(p,p.horizontal?sp.x:sp.y)}
 clampU(p,u){const half=p.len*p.bar.sx/2+6;return Math.max(p.latMin+half,Math.min(p.latMax-half,u))}
 gameStarted(){this.balls[0].timer=.2}
 gameUpdate(dt){this.bounceCool-=dt;
  if(!this.secondBallDone&&this.elapsed>=20){this.secondBallDone=true;this.balls[1].timer=.4;this.bannerAll('ZWEITER BALL!',rgba(.55,1,.55),30,.7);Sfx.play('whistle')}
  if(!this.suddenDeath&&this.elapsed>=42){this.suddenDeath=true;this.bannerAll('SUDDEN DEATH',rgba(1,.35,.3),32,.9);this.flashAll('#f00',.2);Sfx.play('horn')}
  const sdMul=this.suddenDeath?1+(this.elapsed-42)*.035:1;this.sdFactor=this.suddenDeath?Math.max(.7,1-(this.elapsed-42)*.012):1;
  for(const s of this.seats){if(!s.alive)continue;const p=this.paddles[s.index];if(s.isCPU)this.cpuThink(s,p,dt);p.bar.sx+=(this.sdFactor-p.bar.sx)*Math.min(1,dt*3);p.glow.sx=p.bar.sx;
   const maxV=s.isCPU?120+420*s.skill:2800,d=p.target-p.u,step=Math.max(-maxV*dt,Math.min(maxV*dt,d));p.u=this.clampU(p,p.u+step);p.vel=step/Math.max(dt,.001);this.place(p);
   const moving=Math.abs(p.vel)>60;if(moving&&!p.running){p.running=true;p.bear.startRun(.12)}if(!moving&&p.running){p.running=false;p.bear.stopRun()}}
  for(const b of this.balls){if(!b.active){b.timer-=dt;if(b.timer<=0&&!this.finished&&this.aliveSeats.length>1)this.spawn(b);this.updateTrail(b,dt);continue}
   const steps=3,sdt=dt/steps;for(let i=0;i<steps;i++){b.pos.x+=b.vel.x*sdt;b.pos.y+=b.vel.y*sdt;for(const s of this.seats){if(s.alive)this.collide(b,s,this.paddles[s.index])}if(this.walls(b))break}
   if(!b.active){this.updateTrail(b,dt);continue}
   if(Math.abs(b.spin)>.01){const a=b.spin*dt,c=Math.cos(a),sn=Math.sin(a);b.vel={x:b.vel.x*c-b.vel.y*sn,y:b.vel.x*sn+b.vel.y*c};b.spin*=Math.pow(.45,dt)}
   const cur=Math.max(1,Math.hypot(b.vel.x,b.vel.y)),want=Math.min(b.speed,CAP)*sdMul,k=want/cur;b.vel.x*=k;b.vel.y*=k;b.node.x=b.pos.x;b.node.y=b.pos.y;this.updateTrail(b,dt)}
  if(this.seats.some(s=>!s.isCPU)&&!this.humansAlive&&!this.finished){this.humanOutTimer+=dt;if(this.humanOutTimer>3.5)this.finishGame(this.finalScores())}}
 updateTrail(b,dt){for(let i=0;i<b.trail.length;i++){b.trailAge[i]+=dt;const a=Math.max(0,1-b.trailAge[i]/.32);b.trail[i].alpha=a*.5;b.trail[i].setScale(.4+a*.7)}
  if(b.active){b.trailT-=dt;if(b.trailT<=0){b.trailT=.018;const t=b.trail[b.trailIdx];t.x=b.pos.x;t.y=b.pos.y;t.color=b.last>=0?this.seats[b.last].color:'#fff';b.trailAge[b.trailIdx]=0;b.trailIdx=(b.trailIdx+1)%b.trail.length}}}
 spawn(b){const alive=this.aliveSeats;if(!alive.length)return;const target=alive[Math.floor(Math.random()*alive.length)],nin=this.paddles[target.index].nin,a=rr(-.6,.6),dx=-nin.x,dy=-nin.y;
  b.pos={x:this.F.cx+rr(-20,20),y:this.F.cy+rr(-20,20)};b.speed=BASE;b.vel={x:(dx*Math.cos(a)-dy*Math.sin(a))*BASE,y:(dx*Math.sin(a)+dy*Math.cos(a))*BASE};b.spin=0;b.last=-1;b.active=true;b.node.x=b.pos.x;b.node.y=b.pos.y;b.node.hidden=false;b.node.setScale(.1);b.node.run(A.scaleTo(1,.25));
  b.glow.color='#fff';b.body.cbf=0;for(let i=0;i<b.trail.length;i++)b.trailAge[i]=9;Sfx.play('tick')}
 collide(b,s,p){const lat=p.horizontal?b.pos.x:b.pos.y,dLat=lat-p.u,perpD=this.perp(p.edge,b.pos),half=p.len*p.bar.sx/2,pLo=PD-PT/2,pHi=PD+PT/2,cl=Math.max(-half,Math.min(half,dLat)),cp=Math.max(pLo,Math.min(pHi,perpD)),dist=Math.hypot(dLat-cl,perpD-cp);if(dist>=BR)return;
  const la=p.horizontal?{x:1,y:0}:{x:0,y:1},vp=b.vel.x*p.nin.x+b.vel.y*p.nin.y,vl=b.vel.x*la.x+b.vel.y*la.y;
  if(Math.abs(dLat)>half&&perpD<pHi){const sg=dLat>0?1:-1;if(vl*sg<0){const nl=-vl;b.vel={x:p.nin.x*vp+la.x*nl,y:p.nin.y*vp+la.y*nl};const nL=p.u+sg*(half+BR);if(p.horizontal)b.pos.x=nL;else b.pos.y=nL}return}
  if(vp>=0)return;const off=Math.max(-1,Math.min(1,dLat/Math.max(half,1)));let ang=off*.8+Math.max(-.35,Math.min(.35,p.vel/2600));ang=Math.max(-1.05,Math.min(1.05,ang));
  b.speed=Math.min(CAP,b.speed+17);const sp=Math.max(b.speed,Math.hypot(b.vel.x,b.vel.y)),nvp=sp*Math.cos(ang),nvl=sp*Math.sin(ang);b.vel={x:p.nin.x*nvp+la.x*nvl,y:p.nin.y*nvp+la.y*nvl};b.spin=Math.max(-3,Math.min(3,p.vel*.0045));
  const np=pHi+BR+.5,F=this.F;if(p.edge==='bottom')b.pos.y=F.y+np;else if(p.edge==='top')b.pos.y=F.t-np;else if(p.edge==='left')b.pos.x=F.x+np;else b.pos.x=F.r-np;
  b.last=s.index;p.saves++;this.addScore(s,1);this.addStat('hits',1,s);b.glow.color=s.color;b.body.color=s.color;b.body.cbf=.35;b.node.removeAction('pop');b.node.run(A.sequence([A.scaleTo(1.3,.05),A.scaleTo(1,.09)]),'pop');
  p.node.removeAction('hit');p.node.run(A.sequence([A.scaleTo(1.12,.04),A.scaleTo(1,.08)]),'hit');p.bear.squash();this.sparks(b.pos,s.color,sp>430?10:6,sp>430?120:90);Sfx.play(sp>430?'hit':'tap');if(!s.isCPU)Haptic.tap('medium')}
 walls(b){const F=this.F;for(const e of EDGES){const d=this.perp(e,b.pos),si=this.edgeSeat[e];
   if(si!==undefined&&this.seats[si].alive){if(d<-BR*.5){this.lose(b,this.seats[si]);return true}}
   else if(d<BR){const nin=NIN[e];if(e==='bottom')b.pos.y=F.y+BR;else if(e==='top')b.pos.y=F.t-BR;else if(e==='left')b.pos.x=F.x+BR;else b.pos.x=F.r-BR;
    const vp=b.vel.x*nin.x+b.vel.y*nin.y;if(vp<0){b.vel={x:b.vel.x-2*vp*nin.x,y:b.vel.y-2*vp*nin.y};b.spin*=.6;this.wallFlash(e);if(this.bounceCool<=0){this.bounceCool=.06;Sfx.play('bounce')}this.sparks(b.pos,white(.9),3,60)}}}
  return false}
 wallFlash(e){const n=this.edgeNodes[e];if(!n)return;const g=n.glow,si=this.edgeSeat[e];g.removeAction('f');g.run(A.sequence([A.fadeTo(1,.03),A.fadeTo(si!==undefined&&!this.seats[si].alive?.4:.28,.2)]),'f')}
 lose(b,s){const p=this.paddles[s.index],F=this.F;b.active=false;b.node.hidden=true;b.timer=1.4;p.lives--;
  if(p.lives>=0&&p.lives<p.hearts.length)p.hearts[p.lives].run(A.group([A.scaleTo(2,.2),A.fadeTo(.15,.2)]));const red=rgba(1,.3,.3);if(p.lives>0)s.banner('LEBEN WEG',red,26,.5);Sfx.play('miss');Haptic.bad();
  const gp={x:b.pos.x,y:b.pos.y};if(p.edge==='bottom')gp.y=F.y;else if(p.edge==='top')gp.y=F.t;else if(p.edge==='left')gp.x=F.x;else gp.x=F.r;
  this.sparks(gp,s.color,30,180);this.flashAll(s.color,.2);s.flash(red,.5);this.world.removeAction('shake');this.world.x=0;this.world.y=0;const amt=9;
  this.world.run(A.sequence([A.moveBy(amt,amt,.03),A.moveBy(-2*amt,-amt,.05),A.moveBy(amt,-amt*.5,.04),A.moveTo(0,0,.03)]),'shake');
  const gl=this.edgeNodes[p.edge].glow;gl.run(A.sequence([A.fadeTo(1,.05),A.fadeTo(.5,.5)]));
  if(p.lives<=0){p.outOrder=this.outCount++;s.knockOut('RAUS');p.node.run(A.fadeTo(0,.3));p.bear.run(A.fadeTo(.3,.3));if(p.running){p.bear.stopRun();p.running=false}
   const en=this.edgeNodes[p.edge];en.color='#fff';en.cbf=1;en.alpha=.7;en.glow.color='#fff';en.glow.alpha=.3;Sfx.play('lose');
   if(this.aliveSeats.length<=1){for(const ob of this.balls){ob.active=false;ob.node.hidden=true}this.finishGame(this.finalScores())}}}
 sparks(p,color,count,speed){for(let i=0;i<count;i++){const d=new Sprite(Gfx.dot(),6,6);d.color=color;d.cbf=1;d.blend='add';d.x=p.x;d.y=p.y;d.z=40;this.world.add(d);const a=Math.random()*6.28,r=rr(.3,1)*speed;d.run(A.sequence([A.group([A.moveBy(Math.cos(a)*r,Math.sin(a)*r,.45),A.fadeOut(.45),A.scaleTo(.2,.45)]),A.remove()]))}}
 finalScores(){return this.seats.map(s=>{const p=this.paddles[s.index],sv=Math.min(99,p.saves);if(p.outOrder>=0)return p.outOrder*100+sv;return 10000+Math.max(0,p.lives)*1000+sv})}
 timeUp(){this.finishGame(this.finalScores())}
 fold(x,a,b){const w=Math.max(1,b-a);let t=(x-a)%(2*w);if(t<0)t+=2*w;if(t>w)t=2*w-t;return a+t}
 cpuThink(s,p,dt){p.think-=dt;if(p.think>0)return;p.think=.07+(1-s.skill)*.26;let bestT=1e9,best=null,nearest=null,nd=1e9;
  for(const b of this.balls){if(!b.active)continue;const d=this.perp(p.edge,b.pos);if(d<nd){nd=d;nearest=b}const vn=-(b.vel.x*p.nin.x+b.vel.y*p.nin.y);if(vn>30){const t=Math.max(0,d-PD)/vn;if(t<bestT){bestT=t;best=b}}}
  const mid=(p.latMin+p.latMax)/2,half=p.len/2;
  if(best){if(!p.wasApproaching)p.aimOff=rr(-.45,.45)*(.3+.7*s.skill);p.wasApproaching=true;const l0=p.horizontal?best.pos.x:best.pos.y,vl=p.horizontal?best.vel.x:best.vel.y;let x=this.fold(l0+vl*bestT,p.latMin+BR,p.latMax-BR);const err=(1-s.skill)*(22+bestT*60);x+=rr(-err,err);x-=p.aimOff*half;p.target=this.clampU(p,x)}
  else{p.wasApproaching=false;if(nearest){const l0=p.horizontal?nearest.pos.x:nearest.pos.y;p.target=this.clampU(p,mid*.4+l0*.6)}else p.target=this.clampU(p,mid)}}
}
Arcade.register('pong',PongGame);
})();
