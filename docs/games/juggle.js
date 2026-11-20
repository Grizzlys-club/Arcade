(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
class JuggleGame extends MiniScene{
 setupGame(){this.duration=60;this.hadHumans=this.seats.some(s=>!s.isCPU);this.ff=false;this.st=[];
  for(const s of this.seats){const o={pos:{x:0,y:s.h*.12},vel:{x:0,y:0},chain:0,cooldown:0,falling:false,decided:false,trig:0,willHit:true};this.st.push(o);
   const w=s.w,h=s.h,scale=Math.min(1,w/300);
   const floor=new Sprite(Gfx.texture('juggle_floor'+Math.floor(w)+'x'+Math.floor(h),w,h,1,c=>{Gfx.gradientColors(c,rgba(.12,.08,.2,.85),rgba(.04,.03,.08,.9),w,h);c.fillStyle=white(1,.05);c.fillRect(0,0,w,34)}),w,h);floor.z=-10;s.field.add(floor);
   const big=label('0',Math.min(110,w*.45),s.color);big.alpha=.18;big.y=h*.08;big.z=-5;s.field.add(big);o.big=big;
   const sc=Math.max(.8,scale),col=s.color;
   const stick=new Sprite(Gfx.texture('juggle_stick'+col,90,26,2,c=>{c.strokeStyle='rgb(235,235,235)';c.lineWidth=5;c.lineCap='round';c.beginPath();c.moveTo(4,20);c.lineTo(66,10);c.stroke();c.fillStyle=col;SK.rr(c,62,4,26,12,5);c.fill();c.strokeStyle='rgb(38,38,38)';c.lineWidth=6;c.beginPath();c.moveTo(4,20);c.lineTo(20,17.4);c.stroke()}),90*sc,26*sc);
   stick.y=-h/2+18;stick.z=3;s.field.add(stick);o.stick=stick;
   o.r=17*sc;const glow=new Sprite(Gfx.glow(),o.r*5,o.r*5);glow.color=s.color;glow.cbf=1;glow.blend='add';glow.alpha=.55;glow.z=5;s.field.add(glow);o.glow=glow;
   const sh=new Sprite(Gfx.shadow(),o.r*2.4,o.r*.8);sh.z=2;s.field.add(sh);o.shadow=sh;
   const b=new Sprite(Gfx.ball(16),o.r*2,o.r*2);b.z=6;s.field.add(b);o.ball=b;
   // Ball-Spur
   o.trail=[];for(let i=0;i<6;i++){const t=new Sprite(Gfx.dot(),o.r*1.2,o.r*1.2);t.color=s.color;t.cbf=1;t.alpha=0;t.z=4;s.field.add(t);o.trail.push(t)}
   this.place(s,o);
   if(!s.isCPU){const hint=new Node(),l=label('BALL ANTIPPEN!',16,s.color);l.y=-h*.18;hint.add(l);hint.z=50;hint.run(A.forever(A.sequence([A.fadeTo(.4,.4),A.fadeTo(1,.4)])));s.field.add(hint);o.hint=hint}}}
 place(s,o){o.ball.x=o.pos.x;o.ball.y=o.pos.y;o.glow.x=o.pos.x;o.glow.y=o.pos.y;const fy=-s.h/2+10,ht=Math.max(0,o.pos.y-fy);o.shadow.x=o.pos.x;o.shadow.y=fy;const k=Math.max(.3,1-ht/s.h);o.shadow.setScale(k);o.shadow.alpha=k;
  o.trail.unshift(o.trail.pop());const t=o.trail[0];t.x=o.pos.x;t.y=o.pos.y;t.alpha=o.falling?.25:0;o.trail.forEach((q,i)=>{q.setScale(1-i*.14);if(i>0)q.alpha*=.0+Math.max(0,.25-i*.045)/ .25*(o.falling?1:0)})}
 gravity(s,o){return s.h*2.2*(1+o.chain*.035)}
 gameStarted(){for(const o of this.st)o.falling=true}
 began(seat,at){const o=this.st[seat.index],d=Math.hypot(at.x-o.pos.x,at.y-o.pos.y);if(d<o.r*2.2+26)this.kick(seat,o,(o.pos.x-at.x)/(o.r*2.2+26))}
 kick(s,o,offset){if(o.cooldown>0||o.vel.y>0||!o.falling||!s.alive||this.phase!=='playing')return;o.cooldown=.14;o.chain++;this.setScore(s,o.chain);
  const g=this.gravity(s,o),maxY=s.h/2-40-o.r,apex=Math.min(maxY,o.pos.y+s.h*.55),rise=Math.max(s.h*.2,apex-o.pos.y);
  o.vel.y=Math.sqrt(2*g*rise);o.vel.x=Math.max(-1,Math.min(1,offset))*s.w*.9+(Math.random()*40-20);o.decided=false;
  o.ball.run(A.sequence([A.scaleTo(1.35,.05),A.scaleTo(1,.1)]));o.big.text=''+o.chain;o.big.removeAllActions();o.big.run(A.sequence([A.scaleTo(1.25,.06),A.scaleTo(1,.14)]));
  o.stick.run(A.moveToX(Math.max(-s.w/2+45,Math.min(s.w/2-45,o.pos.x)),.12));
  s.burst({x:o.pos.x,y:o.pos.y-o.r},s.color,o.chain%10===0?18:8,90);
  if(o.chain%10===0){s.floatText(o.chain+'!',{x:o.pos.x,y:o.pos.y+30},'#ff0',26);Sfx.play('coin');s.flash('#fff',.18)}else Sfx.play('bounce');
  if(!s.isCPU)Haptic.tap('medium');
  if(o.hint){o.hint.run(A.sequence([A.fadeOut(.2),A.remove()]));o.hint=null}}
 gameUpdate(dtIn){if(this.hadHumans&&!this.humansAlive&&!this.ff&&this.aliveSeats.length>0){this.ff=true;this.bannerAll('»»','#fff',40,.6)}
  const dt=this.ff?dtIn*3:dtIn;
  for(const s of this.seats){if(!s.alive)continue;const o=this.st[s.index];if(!o.falling)continue;o.cooldown-=dt;const g=this.gravity(s,o);
   o.vel.y-=g*dt;o.pos.x+=o.vel.x*dt;o.pos.y+=o.vel.y*dt;o.vel.x*=(1-.4*dt);
   const wx=s.w/2-o.r;if(o.pos.x<-wx){o.pos.x=-wx;o.vel.x=Math.abs(o.vel.x)*.8;Sfx.play('tick')}if(o.pos.x>wx){o.pos.x=wx;o.vel.x=-Math.abs(o.vel.x)*.8;Sfx.play('tick')}
   const top=s.h/2-34-o.r;if(o.pos.y>top){o.pos.y=top;o.vel.y=-Math.abs(o.vel.y)*.5}
   o.ball.rot-=o.vel.x*dt*.05;this.place(s,o);if(s.isCPU)this.cpu(s,o);
   if(o.pos.y<-s.h/2-o.r)this.drop(s,o)}
  this.checkEnd()}
 cpu(s,o){if(o.vel.y>=0)return;if(!o.decided){o.decided=true;o.trig=-s.h/2+s.h*(.18+Math.random()*.14);const p=Math.min(.99,.66+s.skill*.3)-o.chain*.004*(1.1-s.skill);o.willHit=Math.random()<Math.max(.5,p)}
  if(o.willHit&&o.pos.y<=o.trig)this.kick(s,o,-o.pos.x/(s.w*.6)+(Math.random()*.5-.25))}
 drop(s,o){o.falling=false;o.ball.removeAllActions();o.ball.alpha=0;o.glow.alpha=0;o.shadow.alpha=0;o.trail.forEach(t=>t.alpha=0);s.flash('#f00',.3);s.shake(5);Sfx.play('miss');if(!s.isCPU)Haptic.bad();s.knockOut('RAUS · '+o.chain)}
 checkEnd(){if(this.phase!=='playing')return;const alive=this.aliveSeats;if(!alive.length){this.finishGame();return}
  if(alive.length===1&&this.n>1){const a=alive[0],others=Math.max(...this.seats.filter(s=>s!==a).map(s=>s.score));if(a.score>others)this.finishGame()}}
}
Arcade.register('juggle',JuggleGame);
})();
