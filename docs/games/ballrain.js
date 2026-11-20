(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
const IR=11,BA=SK_BEAR_ASPECT();
function SK_BEAR_ASPECT(){return 918/777}
class BallRainGame extends MiniScene{
 setupGame(){this.duration=30;this.st=[];
  for(const s of this.seats){const o={rand:this.newRand(),bearX:0,targetX:0,items:[],spawnTimer:.4,cpuRetarget:0,combo:0};this.st.push(o);const w=s.w,h=s.h,scale=Math.min(1,w/300);
   const sky=new Sprite(Gfx.texture('rain_sky'+Math.floor(w)+'x'+Math.floor(h),w,h,1,c=>{Gfx.gradientColors(c,rgba(.04,.06,.18,.9),rgba(.1,.14,.3,.85),w,h);c.fillStyle='rgba(255,255,255,.5)';let seed=Math.floor(w*7+h)>>>0;for(let i=0;i<40;i++){seed=(Math.imul(seed,1664525)+1013904223)>>>0;const x=seed%Math.max(1,Math.floor(w));seed=(Math.imul(seed,1664525)+1013904223)>>>0;const y=seed%Math.max(1,Math.floor(h*.7));c.fillRect(x,y,1.6,1.6)}}),w,h);sky.z=-10;s.field.add(sky);
   o.floorY=-h/2+8;const ground=new Sprite(Gfx.rect(w,6,alpha(s.color,.5),3),w,6);ground.y=o.floorY-2;ground.z=1;s.field.add(ground);
   o.bearH=Math.min(64,h*.17)*Math.max(.85,scale);o.bearW=o.bearH*BA;const b=this.makeBear(s,o.bearH,false);b.y=o.floorY;b.z=5;s.field.add(b);o.bear=b;
   const glow=new Sprite(Gfx.glow(),o.bearW*1.6,o.bearH*.9);glow.color=s.color;glow.cbf=1;glow.blend='add';glow.alpha=.35;glow.y=o.bearH*.75;glow.z=-1;b.add(glow);
   if(!s.isCPU){const hint=new Node(),l=label('← FINGER ZIEHEN →',15,s.color);l.y=o.floorY+o.bearH+30;hint.add(l);hint.z=50;s.field.add(hint);o.hint=hint}}}
 cardTex(){return Gfx.texture('rain_card',18,25,2,c=>{c.fillStyle='rgb(255,217,13)';SK.rr(c,1,1,16,23,3);c.fill();c.strokeStyle='rgb(128,89,0)';c.lineWidth=1.5;SK.rr(c,1,1,16,23,3);c.stroke()})}
 began(seat,at){const o=this.st[seat.index];o.targetX=at.x;if(o.hint){o.hint.run(A.sequence([A.fadeOut(.3),A.remove()]));o.hint=null}}
 moved(seat,at){this.st[seat.index].targetX=at.x}
 gameUpdate(dt){for(const s of this.seats){const o=this.st[s.index];o.spawnTimer-=dt;if(o.spawnTimer<=0){this.spawn(s,o);o.spawnTimer=Math.max(.26,.62-this.elapsed*.012)}
   if(s.isCPU)this.cpu(s,o,dt);const lim=s.w/2-o.bearW*.4,tgt=Math.max(-lim,Math.min(lim,o.targetX)),d=tgt-o.bearX;
   if(s.isCPU){const ms=s.w*(.8+s.skill*1.5);o.bearX+=Math.max(-ms*dt,Math.min(ms*dt,d))}else o.bearX+=d*Math.min(1,dt*20);
   o.bear.x=o.bearX;if(Math.abs(d)>3){o.bear.setFacing(d>0);o.bear.rot=Math.max(-.15,Math.min(.15,-d*.004))}else o.bear.rot*=.8;
   const catchTop=o.floorY+o.bearH*.95,catchBottom=o.floorY+o.bearH*.25;
   for(const it of o.items){if(it.done)continue;it.y-=it.speed*dt;it.node.y=it.y;it.node.rot+=it.spin*dt;
    if(it.y<=catchTop&&it.y>=catchBottom&&Math.abs(it.x-o.bearX)<o.bearW*.5+IR*.5)this.caught(s,o,it);
    else if(it.y<o.floorY-IR){it.done=true;it.node.run(A.sequence([A.fadeOut(.15),A.remove()]));if(it.kind!=='card')o.combo=0}}
   o.items=o.items.filter(i=>!i.done)}}
 spawn(s,o){const r=o.rand,x=r.range(-s.w/2+16,s.w/2-16),roll=r.double(),kind=roll<.13?'gold':(roll<.33?'card':'white'),speed=s.h*(.42+this.elapsed*.018+r.range(0,.18))*(kind==='gold'?1.2:1),spin=r.range(-4,4);let node;
  if(kind==='white')node=new Sprite(Gfx.ball(14),IR*2,IR*2);
  else if(kind==='gold'){node=new Sprite(Gfx.ball(14),IR*2.2,IR*2.2);node.color=rgba(1,.8,.1);node.cbf=.75;const g=new Sprite(Gfx.glow(),IR*5,IR*5);g.color='#ff0';g.cbf=1;g.blend='add';g.alpha=.7;g.z=-1;node.add(g);g.run(A.forever(A.sequence([A.fadeTo(.4,.3),A.fadeTo(.8,.3)])))}
  else node=new Sprite(this.cardTex(),18,25);
  node.x=x;node.y=s.h/2-34;node.z=8;node.alpha=0;node.run(A.fadeIn(.15));s.field.add(node);o.items.push({node,kind,x,y:node.y,speed,spin,done:false})}
 caught(s,o,it){it.done=true;it.node.removeAllActions();it.node.removeFromParent();const p={x:it.x,y:it.y+10};
  if(it.kind==='white'){this.addScore(s,1);this.addStat('balls',1,s);o.combo++;s.floatText('+1',p,s.color,18);s.burst(p,'#fff',6,70);Sfx.play('pop');if(!s.isCPU)Haptic.tap()}
  else if(it.kind==='gold'){this.addScore(s,3);this.addStat('balls',1,s);o.combo++;s.floatText('+3',p,'#ff0',26);s.burst(p,'#ff0',22,130);s.flash('#ff0',.12);Sfx.play('coin');if(!s.isCPU)Haptic.good()}
  else{this.setScore(s,Math.max(0,s.score-3));o.combo=0;s.floatText('-3',p,'#f00',24);s.flash(rgba(1,.85,0),.3);s.shake(5);Sfx.play('wrong');if(!s.isCPU)Haptic.bad()}
  o.bear.squash();if(o.combo>0&&o.combo%10===0)s.banner(o.combo+'ER SERIE!',s.color,28,.5)}
 cpu(s,o,dt){o.cpuRetarget-=dt;if(o.cpuRetarget>0)return;o.cpuRetarget=.08+(1-s.skill)*.25;const catchY=o.floorY+o.bearH*.6,ms=s.w*(.8+s.skill*1.5);let best=null,bv=-1;
  for(const it of o.items){if(it.done||it.kind==='card'||it.y<=catchY)continue;const t=(it.y-catchY)/it.speed,dist=Math.abs(it.x-o.bearX);if(dist>ms*t+o.bearW*.4)continue;const v=(it.kind==='gold'?3:1)/(t+.3);if(v>bv){bv=v;best=it}}
  let tx=best?best.x:o.bearX*.9;
  for(const it of o.items){if(it.done||it.kind!=='card'||it.y<=catchY)continue;const t=(it.y-catchY)/it.speed;if(t<.45&&Math.abs(it.x-tx)<o.bearW*.6&&Math.random()<s.skill+.2)tx=it.x+(it.x>o.bearX?-1:1)*o.bearW*.9}
  o.targetX=tx+(Math.random()*2-1)*o.bearW*.3*(1-s.skill)}
}
Arcade.register('ballrain',BallRainGame);
})();
