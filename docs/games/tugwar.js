(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
const SW=SKC.SW,KS=38,TH=.35,LIM=20,rr=(a,b)=>a+Math.random()*(b-a);
class TugWarGame extends MiniScene{
 setupGame(){this.duration=0;this.useCountdown=true;this.R=Math.min(340,(this.bandY-SKC.bottomInset)-36);this.pullers=[];this.state='ready';this.round=1;this.f=0;this.fv=0;this.readyT=0;this.roundT=0;this.overT=0;this.clock=0;this.knots=[];
  if(this.seats.length<2)return;for(let i=2;i<this.seats.length;i++)this.seats[i].knockOut('—');
  for(let i=0;i<2;i++)this.pullers.push({seat:this.seats[i],heat:0,wins:0,roundTaps:0,totalPull:0,nextTap:0,phase:Math.random()*6.28,restUntil:0,rateJitter:rr(.92,1.08)});
  const R=this.R,rope=this.rope=new Node();rope.x=SW/2;rope.y=this.bandY;rope.z=5;this.world.add(rope);const len=R*2+60;
  const ropeTex=Gfx.texture('tugwar_rope',10,64,2,c=>{c.fillStyle='rgb(199,153,87)';c.fillRect(0,0,10,64);c.strokeStyle='rgb(115,77,36)';c.lineWidth=2;c.beginPath();for(let y=-4;y<68;y+=8){c.moveTo(0,y);c.lineTo(10,y+8)}c.stroke()});
  rope.add(new Sprite(ropeTex,9,len));const rg=new Sprite(Gfx.glow(),34,len);rg.color=rgba(1,.8,.4);rg.cbf=1;rg.blend='add';rg.alpha=.25;rg.z=-1;rope.add(rg);
  const nk=Math.floor(len/KS)+2;for(let i=0;i<nk;i++){const k=new Sprite(Gfx.circle(5,rgba(.5,.33,.15)),12,12);k.z=1;rope.add(k);this.knots.push(k)}
  for(let i=0;i<2;i++){const s=this.seats[i],y=this.bandY+(i===0?-R:R),line=new Sprite(Gfx.rect(SW-30,3,s.color),SW-30,3);line.x=SW/2;line.y=y;line.alpha=.8;line.z=4;this.world.add(line);
   const g=new Sprite(Gfx.glow(),SW,50);g.color=s.color;g.cbf=1;g.blend='add';g.alpha=.45;g.x=SW/2;g.y=y;g.z=4;this.world.add(g);g.run(A.forever(A.sequence([A.fadeTo(.25,.7),A.fadeTo(.5,.7)])))}
  const mid=new Sprite(Gfx.rect(60,2,white(1,.5)),60,2);mid.x=SW/2;mid.y=this.bandY;mid.z=4;mid.alpha=.5;this.world.add(mid);
  this.flag=new Node();this.flag.z=40;this.flag.x=SW/2;this.flag.y=this.bandY;this.world.add(this.flag);
  const ft=Gfx.texture('tugwar_flag',76,26,2,c=>{c.fillStyle='#fff';SK.rr(c,2,2,72,22,6);c.fill();c.strokeStyle='rgb(38,38,38)';c.lineWidth=3;SK.rr(c,2,2,72,22,6);c.stroke();c.fillStyle='rgba(38,38,38,.9)';for(let x=10;x<66;x+=14)c.fillRect(x,6,7,14)});
  this.flagSprite=new Sprite(ft,76,26);this.flagSprite.color='#fff';this.flagSprite.cbf=0;this.flagSprite.z=2;this.flag.add(this.flagSprite);
  this.flagGlow=new Sprite(Gfx.glow(),120,70);this.flagGlow.blend='add';this.flagGlow.color='#fff';this.flagGlow.cbf=1;this.flagGlow.alpha=.6;this.flag.add(this.flagGlow);
  for(const p of this.pullers){const s=p.seat,bh=Math.min(88,s.h*.24),bear=this.makeBear(s,bh,true),bw=bh*SKC.bearAspect;bear.x=-bw*.34;bear.y=-s.h/2+34;bear.z=20;s.node.add(bear);p.bear=bear;bear.startBob(2,.3);p.bx=bear.x;
   const ring=new Sprite(Gfx.circle(34,alpha(s.color,.18),s.color),68,68);ring.x=92;ring.y=-s.h/2+70;ring.z=15;s.node.add(ring);p.ring=ring;
   const rgl=new Sprite(Gfx.glow(),130,130);rgl.color=s.color;rgl.cbf=1;rgl.blend='add';rgl.alpha=.4;ring.add(rgl);const t=label('TAP',20,'#fff');t.z=1;ring.add(t);
   if(!s.isCPU){const hint=label('SCHNELL TIPPEN!',16,'#fff');hint.y=-s.h/2+140;hint.z=420;s.node.add(hint);hint.run(A.sequence([A.wait(5),A.fadeOut(.5),A.remove()]))}}
  this.roundLabel=label('RUNDE 1/3',13,Theme.orange);this.roundLabel.x=SW-62;this.roundLabel.y=this.bandY;this.hud.add(this.roundLabel);this.updateKnots()}
 gameStarted(){if(this.pullers.length<2){this.finishGame();return}this.beginRound(true)}
 beginRound(first){this.f=0;this.fv=0;this.roundT=0;for(const p of this.pullers){p.heat=0;p.roundTaps=0;p.nextTap=this.clock+.4;p.restUntil=0;p.rateJitter=rr(.92,1.08)}
  this.state='ready';this.readyT=first?.5:1.5;this.roundLabel.text='RUNDE '+this.round+'/3';this.bannerAll('RUNDE '+this.round,'#fff',40,.9)}
 began(seat){if(seat.index>=2||this.state!=='active')return;this.tap(this.pullers[seat.index],true)}
 tap(p,human){p.heat+=1;p.roundTaps++;const s=p.seat;p.bear.removeAction('pull');p.bear.run(A.sequence([A.group([A.rotateTo(.16,.05),A.moveToX(p.bx-5,.05)]),A.group([A.rotateTo(0,.1),A.moveToX(p.bx,.1)])]),'pull');p.bear.squash();
  p.ring.removeAction('pulse');p.ring.setScale(1);p.ring.run(A.sequence([A.scaleTo(1.22,.04),A.scaleTo(1,.08)]),'pulse');
  const bw=p.bear.height*SKC.bearAspect,fx=p.bear.x-bw*.25,fy=p.bear.y+2;
  for(let i=0;i<2;i++){const sz=rr(7,12),d=new Sprite(Gfx.dot(),sz,sz);d.color=rgba(.85,.78,.62);d.cbf=1;d.alpha=.6;d.x=fx+rr(-8,8);d.y=fy;d.z=18;s.node.add(d);d.run(A.sequence([A.group([A.moveBy(rr(-34,-8),rr(6,22),.4),A.fadeOut(.4),A.scaleTo(2,.4)]),A.remove()]))}
  if(human){Sfx.play('tap');Haptic.tap()}}
 gameUpdate(dt){if(this.pullers.length<2)return;this.clock+=dt;const P=this.pullers;
  if(this.state==='ready'){this.readyT-=dt;if(this.readyT<=0){this.state='active';this.roundT=0;for(const p of P)p.nextTap=this.clock+rr(.05,.25);this.bannerAll('ZIEH!',Theme.orange,46,.4);Sfx.play('go')}}
  else if(this.state==='active'){this.roundT+=dt;
   for(const p of P){if(!p.seat.isCPU)continue;if(this.clock>=p.nextTap){if(this.clock<p.restUntil){p.nextTap=p.restUntil;continue}this.tap(p,false);const sk=p.seat.skill,wob=1+.22*Math.sin(this.clock*2.3+p.phase)+.1*Math.sin(this.clock*5.1+p.phase*2),rate=(3+4.6*sk)*p.rateJitter*wob;let iv=1/Math.max(1.5,rate)*rr(.8,1.2);if(Math.random()<.05*(1.2-sk))iv+=rr(.25,.5);p.nextTap=this.clock+iv}}
   const decay=Math.exp(-dt/.5);for(const p of P)p.heat*=decay;const diff=P[0].heat-P[1].heat;let target=0;if(Math.abs(diff)>TH)target=(Math.abs(diff)-TH)*.22*(diff>0?1:-1);
   this.fv+=(target-this.fv)*Math.min(1,dt*6);this.f+=this.fv*dt;const mv=Math.abs(this.fv*dt);if(this.fv>0)P[0].totalPull+=mv;else P[1].totalPull+=mv;this.f=Math.max(-1,Math.min(1,this.f));this.updateKnots();
   if(this.f>=1)this.endRound(0);else if(this.f<=-1)this.endRound(1);
   else if(this.roundT>=LIM){if(Math.abs(this.f)>.02)this.endRound(this.f>0?0:1);else{const a=P[0].roundTaps,b=P[1].roundTaps;this.endRound(a===b?Math.floor(Math.random()*2):(a>b?0:1))}}}
  else{this.overT-=dt;if(this.overT<=0){if(P[0].wins>=2||P[1].wins>=2||this.round>=3){this.state='ready';this.readyT=999;this.finishAll()}else{this.round++;this.beginRound(false)}}}}
 updateKnots(){const R=this.R,f=this.f,P=this.pullers;this.flag.x=SW/2;this.flag.y=this.bandY-f*R;const a=Math.abs(f),lead=f>=0?P[0].seat.color:P[1].seat.color;
  this.flagGlow.color=a>.05?lead:'#fff';this.flagGlow.alpha=.45+.4*a;this.flagGlow.w=120+40*a;this.flagGlow.h=70+20*a;this.flagSprite.color=lead;this.flagSprite.cbf=.35*a;
  const len=R*2+60,span=this.knots.length*KS;this.knots.forEach((k,i)=>{let y=(i*KS-f*R)%span;if(y<0)y+=span;k.x=0;k.y=y-len/2-(span-len)/2})}
 endRound(winner){this.state='over';this.overT=2.2;const P=this.pullers,w=P[winner],l=P[1-winner];w.wins++;this.setScore(w.seat,w.wins);
  for(const p of P)p.seat.shake(11);
  const acts=[];for(let i=0;i<6;i++)acts.push(A.moveTo(rr(-7,7),rr(-7,7),.035));acts.push(A.moveTo(0,0,.035));this.world.run(A.sequence(acts),'wshake');
  this.flashAll(w.seat.color,.35);w.seat.banner('RUNDE GEWONNEN!','#ff0',30,1.2);l.seat.banner('VERLOREN',white(1,.8),30,1.2);w.seat.burst({x:0,y:-w.seat.h/2+120},w.seat.color,34,220);w.bear.celebrate();
  l.bear.run(A.group([A.rotateTo(.5,.2),A.moveToX(l.bx-12,.2)]));l.bear.run(A.sequence([A.wait(1.6),A.group([A.rotateTo(0,.3),A.moveToX(l.bx,.3)])]));
  for(let i=0;i<22;i++){const d=new Sprite(Gfx.dot(),12,12);d.color=rgba(.85,.78,.62);d.cbf=1;d.alpha=.7;d.x=this.flag.x;d.y=this.flag.y;d.z=45;this.world.add(d);const a=Math.random()*6.28,dist=rr(30,100);d.run(A.sequence([A.group([A.moveBy(Math.cos(a)*dist,Math.sin(a)*dist,.6),A.fadeOut(.6),A.scaleTo(2.5,.6)]),A.remove()]))}
  const ring=new Sprite(Gfx.circle(20,'rgba(0,0,0,0)',w.seat.color),40,40);ring.blend='add';ring.x=this.flag.x;ring.y=this.flag.y;ring.z=46;this.world.add(ring);ring.run(A.sequence([A.group([A.scaleTo(9,.6),A.fadeOut(.6)]),A.remove()]));
  for(const p of P){if(!p.seat.isCPU){if(p===w){Sfx.play('win');Haptic.good()}else{Sfx.play('lose');Haptic.bad()}}}
  if(P.every(p=>p.seat.isCPU))Sfx.play('horn')}
 finishAll(){const a=this.pullers[0],b=this.pullers[1];let s0=a.wins*10,s1=b.wins*10;if(s0===s1){if(a.totalPull>=b.totalPull)s0++;else s1++}this.finishGame([s0,s1])}
}
Arcade.register('tugwar',TugWarGame);
})();
