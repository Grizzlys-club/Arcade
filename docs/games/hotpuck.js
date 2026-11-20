(()=>{
const {Node,Sprite,Label,A,Gfx,Theme,rgba,white,label}=SK;
class HotPuckGame extends MiniScene{
 static get layout(){return 'arena'}
 static get stripThickness(){return 104}
 setupGame(){this.duration=75;this.holders=[];this.holder=-1;this.need=3;this.flying=false;this.fuse=8;this.roundTime=0;this.tickTimer=0;this.roundActive=false;this.outCount=0;this.passes=0;
  const ar=this.arena,tw=Math.floor(ar.w),th=Math.floor(ar.h);
  const table=new Sprite(Gfx.texture('hotpuck_table_'+tw+'x'+th,tw,th,1,c=>{Gfx.gradientColors(c,rgba(.14,.05,.05),rgba(.05,.02,.04),tw,th);c.strokeStyle='rgba(255,102,26,.16)';c.lineWidth=2;for(let i=1;i<6;i++){const r=i*Math.min(tw,th)*.09;c.beginPath();c.arc(tw/2,th/2,r,0,7);c.stroke()}}),ar.w,ar.h);
  table.x=ar.x+ar.w/2;table.y=ar.y+ar.h/2;table.z=-20;this.world.add(table);
  const d=Math.min(ar.w,ar.h)*.5,logo=new Sprite(Gfx.logo,d,d);logo.x=ar.x+ar.w/2;logo.y=ar.y+ar.h/2;logo.alpha=.12;logo.z=-19;this.world.add(logo);
  // Extra: lodernde Glutringe am Tisch, die mit der Zündschnur heißer werden
  this.heatRing=new Sprite(Gfx.circle(Math.min(ar.w,ar.h)*.45,'rgba(0,0,0,0)',rgba(1,.3,.05)),Math.min(ar.w,ar.h)*.9,Math.min(ar.w,ar.h)*.9);this.heatRing.x=ar.x+ar.w/2;this.heatRing.y=ar.y+ar.h/2;this.heatRing.blend='add';this.heatRing.alpha=0;this.heatRing.z=-18;this.world.add(this.heatRing);
  for(const s of this.seats){const h={lives:3,hearts:[],baseText:s.isCPU?'CPU':'TIPPEN!',outOrder:-1,cpuTimer:0},bw=Math.min(s.w-40,220);
   const btn=this.button(h.baseText,bw,Math.min(54,s.h-44),alpha(s.color,.5),'#fff',18);btn.y=-8;btn.z=410;s.node.add(btn);h.button=btn;h.counter=btn.children.find(c=>c instanceof Label);
   for(let i=0;i<3;i++){const heart=label('♥',16,rgba(1,.25,.3));heart.x=-s.w/2+18+i*17;heart.y=-s.h/2+12;heart.z=412;s.node.add(heart);h.hearts.push(heart)}
   this.setScore(s,3);this.holders.push(h)}
  const puck=this.puck=new Node();
  this.puckGlow=new Sprite(Gfx.glow(),90,90);this.puckGlow.color=rgba(1,.45,.05);this.puckGlow.cbf=1;this.puckGlow.blend='add';puck.add(this.puckGlow);
  this.flame=new Sprite(Gfx.glow(),50,70);this.flame.color=rgba(1,.8,.2);this.flame.cbf=1;this.flame.blend='add';this.flame.alpha=.6;this.flame.y=14;puck.add(this.flame);
  this.puckCore=new Sprite(Gfx.circle(18,white(.08),rgba(1,.5,.1)),36,36);this.puckCore.z=1;puck.add(this.puckCore);
  const fire=label('🔥',18);fire.z=2;puck.add(fire);puck.x=ar.x+ar.w/2;puck.y=ar.y+ar.h/2;puck.z=50;this.world.add(puck);
  puck.run(A.forever(A.sequence([A.rotateBy(.15,.05),A.rotateBy(-.15,.05)])))}
 gameStarted(){this.newRound()}
 holdPoint(s){return s.toScene({x:0,y:s.h/2+46})}
 newRound(){const alive=this.aliveSeats;if(alive.length<=1)return;const start=alive[Math.floor(Math.random()*alive.length)];this.fuse=5+Math.random()*6;this.roundTime=0;this.roundActive=true;this.tickTimer=0;
  this.puck.alpha=1;this.puck.setScale(.1);this.puck.x=this.arena.x+this.arena.w/2;this.puck.y=this.arena.y+this.arena.h/2;this.puck.run(A.scaleTo(1,.25));this.give(start,null)}
 give(s,from){this.flying=true;this.holder=s.index;this.need=3+Math.floor(Math.random()*4);for(const h of this.holders)h.counter.text=h.baseText;
  const t=this.holdPoint(s);this.puck.run(A.sequence([SK.easeOut(A.moveTo(t.x,t.y,from?.22:.35)),A.run(()=>{this.flying=false;this.updateHolderUI()})]),'fly');this.updateHolderUI()}
 updateHolderUI(){for(const s of this.seats){const h=this.holders[s.index],is=s.index===this.holder&&s.alive;h.button.removeAction('pulse');
  if(is){h.button.alpha=1;h.counter.text=h.baseText+' '+this.need+'×';h.button.run(A.forever(A.sequence([A.scaleTo(1.06,.15),A.scaleTo(1,.15)])),'pulse')}
  else{h.button.alpha=s.alive?.45:.15;h.button.setScale(1);h.counter.text=h.baseText}}}
 began(seat){this.tap(seat)}
 tap(s){if(!this.roundActive||this.flying||s.index!==this.holder||!s.alive)return;this.need--;Sfx.play('tap');if(!s.isCPU)Haptic.tap();const h=this.holders[s.index];h.counter.text=h.baseText+' '+Math.max(0,this.need)+'×';
  h.button.run(A.sequence([A.scaleTo(.9,.04),A.scaleTo(1,.06)]));this.puckCore.run(A.sequence([A.scaleTo(1.3,.04),A.scaleTo(1,.06)]));
  const p=this.puck;for(let i=0;i<3;i++){const d=new Sprite(Gfx.dot(),6,6);d.color=rgba(1,.7,.2);d.cbf=1;d.blend='add';d.x=p.x;d.y=p.y;d.z=49;this.world.add(d);const a=Math.random()*6.28;d.run(A.sequence([A.group([A.moveBy(Math.cos(a)*40,Math.sin(a)*40,.3),A.fadeOut(.3)]),A.remove()]))}
  if(this.need<=0){const others=this.aliveSeats.filter(x=>x.index!==s.index);if(others.length){const t=others[Math.floor(Math.random()*others.length)];this.passes++;Sfx.play('kick');this.give(t,s)}}}
 gameUpdate(dt){if(!this.roundActive)return;this.roundTime+=dt;const heat=Math.min(1,this.roundTime/9);
  this.puckGlow.setScale(1+heat*1.2+Math.sin(this.roundTime*18)*.08*(1+heat));this.puckGlow.alpha=.6+heat*.4;this.flame.setScale(1+heat);this.heatRing.alpha=heat*.25*(.6+.4*Math.sin(this.roundTime*10));
  this.tickTimer-=dt;if(this.tickTimer<=0){this.tickTimer=Math.max(.12,.6-this.roundTime*.055);Sfx.play('tick')}
  for(const s of this.seats){if(!s.isCPU||!s.alive||s.index!==this.holder||this.flying)continue;const h=this.holders[s.index];h.cpuTimer-=dt;if(h.cpuTimer<=0){h.cpuTimer=(.36-.22*s.skill)*(.75+Math.random()*.55);this.tap(s)}}
  if(this.roundTime>=this.fuse&&!this.flying)this.explode()}
 explode(){this.roundActive=false;if(this.holder<0||this.holder>=this.seats.length)return;const s=this.seats[this.holder],h=this.holders[s.index];h.lives--;
  if(h.lives>=0&&h.lives<h.hearts.length)h.hearts[h.lives].run(A.group([A.scaleTo(2,.2),A.fadeTo(.1,.2)]));this.setScore(s,Math.max(0,h.lives));Sfx.play('stomp');Sfx.play('lose');if(!s.isCPU)Haptic.bad();
  this.flashAll(rgba(1,.5,.1),.55);this.heatRing.alpha=0;
  this.world.run(A.sequence([A.moveBy(12,6,.03),A.moveBy(-22,-10,.05),A.moveBy(16,6,.05),A.moveBy(-6,-2,.04)]));
  const p={x:this.puck.x,y:this.puck.y};
  for(let i=0;i<44;i++){const d=new Sprite(Gfx.dot(),10,10);d.color=i%2===0?rgba(1,.6,.1):'#ff0';d.cbf=1;d.blend='add';d.x=p.x;d.y=p.y;d.z=60;this.world.add(d);const a=Math.random()*6.28,r=60+Math.random()*150;d.run(A.sequence([A.group([A.moveBy(Math.cos(a)*r,Math.sin(a)*r,.6),A.fadeOut(.6),A.scaleTo(.3,.6)]),A.remove()]))}
  const ring=new Sprite(Gfx.circle(30,'rgba(0,0,0,0)','#ff0'),60,60);ring.blend='add';ring.x=p.x;ring.y=p.y;ring.z=60;this.world.add(ring);ring.run(A.sequence([A.group([A.scaleTo(6,.5),A.fadeOut(.5)]),A.remove()]));
  const boom=label('💥',70);boom.x=p.x;boom.y=p.y;boom.z=70;this.world.add(boom);boom.run(A.sequence([A.scaleTo(1.7,.3),A.fadeOut(.3),A.remove()]));
  this.puck.alpha=0;s.flash('#f80',.6);s.banner('BUMM!','#f80',30,.6);
  if(h.lives<=0){h.outOrder=this.outCount++;s.knockOut('RAUS')}
  this.holder=-1;this.updateHolderUI();
  if(this.aliveSeats.length<=1){this.finishGame(this.finalScores());return}
  this.run(A.sequence([A.wait(1.6),A.run(()=>{if(this.phase==='playing')this.newRound()})]))}
 finalScores(){return this.seats.map(s=>{const h=this.holders[s.index],surv=h.outOrder>=0?h.outOrder:this.n;return Math.max(0,h.lives)*100+surv*10})}
 timeUp(){this.finishGame(this.finalScores())}
}
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
Arcade.register('hotpuck',HotPuckGame);
})();
