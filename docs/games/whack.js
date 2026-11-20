(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const holeTex=()=>Gfx.texture('whack_hole',90,40,2,c=>{c.fillStyle='rgba(0,0,0,.9)';c.beginPath();c.ellipse(45,20,42,16,0,0,7);c.fill();c.strokeStyle='rgba(255,255,255,.18)';c.lineWidth=3;c.beginPath();c.ellipse(45,20,42,16,0,0,7);c.stroke()});
const eyes=c=>{c.fillStyle='#fff';c.beginPath();c.ellipse(25.5,36.5,5.5,5.5,0,0,7);c.fill();c.beginPath();c.ellipse(44.5,36.5,5.5,5.5,0,0,7);c.fill();c.fillStyle='#000';c.beginPath();c.ellipse(26.5,37.5,2.5,2.5,0,0,7);c.fill();c.beginPath();c.ellipse(45.5,37.5,2.5,2.5,0,0,7);c.fill()};
const moleTex=k=>k==='puck'?Gfx.texture('whack_puck',70,54,2,c=>{c.fillStyle='rgb(26,26,26)';c.fillRect(4,14,62,26);c.beginPath();c.ellipse(35,40,31,10,0,0,7);c.fill();c.fillStyle='rgb(56,56,56)';c.beginPath();c.ellipse(35,14,31,10,0,0,7);c.fill();c.fillStyle='#ff8a00';c.fillRect(4,26,62,4);eyes(c)})
 :k==='gold'?Gfx.texture('whack_gold',70,54,2,c=>{c.fillStyle='rgb(217,153,0)';c.fillRect(4,14,62,26);c.beginPath();c.ellipse(35,40,31,10,0,0,7);c.fill();c.fillStyle='rgb(255,217,51)';c.beginPath();c.ellipse(35,14,31,10,0,0,7);c.fill();eyes(c)})
 :Gfx.texture('whack_card',70,54,2,c=>{SK.rr(c,18,2,34,48,5);c.fillStyle='rgb(255,217,26)';c.fill();c.strokeStyle='#fff';c.lineWidth=3;SK.rr(c,18,2,34,48,5);c.stroke();c.fillStyle='#000';c.fillRect(24,30,22,4)});
class WhackGame extends MiniScene{
 setupGame(){this.duration=30;const wide=(this.seats[0]?this.seats[0].w:200)>260;this.cols=wide?4:3;this.rows=wide?3:4;const r=this.newRand();this.events=[];let t=.4;
  while(t<this.duration-.6){const p=t/this.duration,roll=r.double(),kind=roll<.1?'gold':(roll<.25?'card':'puck'),up=(1.2-.55*p)*(kind==='gold'?.75:1);
   this.events.push({time:t,hole:r.int(0,this.cols*this.rows-1),kind,up});
   if(r.chance(.25+.3*p))this.events.push({time:t+.05,hole:r.int(0,this.cols*this.rows-1),kind:r.chance(.3)?'card':'puck',up});t+=(.75-.42*p)*r.range(.8,1.2)}
  this.st=[];
  for(const s of this.seats){const g={holes:[],moles:{},nextEvent:0},top=s.h/2-40,bottom=-s.h/2+16;g.cw=s.w/this.cols;g.ch=(top-bottom)/this.rows;
   for(let row=0;row<this.rows;row++)for(let c=0;c<this.cols;c++){const x=-s.w/2+g.cw*(c+.5),y=bottom+g.ch*(row+.3);g.holes.push({x,y});const hw=Math.min(g.cw*.82,84),hole=new Sprite(holeTex(),hw,hw*.42);hole.x=x;hole.y=y;hole.z=1;s.field.add(hole)}
   this.st.push(g);const hint=label('TIPP DIE PUCKS!',Math.min(18,s.w*.085),'#fff');hint.z=60;s.field.add(hint);hint.run(A.sequence([A.wait(4.4),A.fadeOut(.4),A.remove()]))}}
 pop(s,e){const g=this.st[s.index];const old=g.moles[e.hole];if(old){old.alive=false;old.node.removeFromParent()}
  const hw=Math.min(g.cw*.72,70),node=new Sprite(moleTex(e.kind),hw,hw*54/70);node.ay=.15;const base=g.holes[e.hole];node.x=base.x;node.y=base.y;node.z=2;node.sy=.1;s.field.add(node);node.run(A.scaleYTo(1,.09));
  if(e.kind==='gold'){const glow=new Sprite(Gfx.glow(),hw*1.6,hw*1.6);glow.color='#ff0';glow.cbf=1;glow.blend='add';glow.alpha=.5;glow.y=hw*.3;glow.z=-1;node.add(glow)}
  const m={node,kind:e.kind,hole:e.hole,until:this.elapsed+e.up,alive:true,cpuAt:null};
  if(s.isCPU){const react=.22+(1-s.skill)*.55+Math.random()*.2,p=e.kind==='card'?(1-s.skill)*.25:.45+.5*s.skill;if(Math.random()<p&&react<e.up)m.cpuAt=this.elapsed+react}
  g.moles[e.hole]=m}
 hide(m){m.alive=false;m.node.run(A.sequence([A.scaleYTo(.05,.08),A.remove()]))}
 whack(s,m){if(!m.alive)return;m.alive=false;const g=this.st[s.index];delete g.moles[m.hole];const p={x:g.holes[m.hole].x,y:g.holes[m.hole].y+m.node.h*.4};
  if(m.kind==='puck'){this.addScore(s,1);this.addStat('hits',1,s);s.floatText('+1',p,'#fff');Sfx.play('hit');if(!s.isCPU)Haptic.tap('medium')}
  else if(m.kind==='gold'){this.addScore(s,3);this.addStat('hits',1,s);s.floatText('+3',p,'#ff0',26);Sfx.play('coin');if(!s.isCPU)Haptic.good()}
  else{this.setScore(s,Math.max(0,s.score-2));s.floatText('-2',p,rgba(1,.3,.3),26);s.flash('#f00',.4);s.shake(6);Sfx.play('whistle');if(!s.isCPU)Haptic.bad()}
  s.burst(p,m.kind==='card'?'#f00':(m.kind==='gold'?'#ff0':s.color),10,80);
  const sh=Math.min(60,g.ch*.8),stick=new Sprite(null,6,sh,'#fff');stick.ay=0;stick.x=p.x+18;stick.y=p.y-6;stick.rot=-.9;stick.z=40;const blade=new Sprite(null,18,8,s.color);blade.x=-6;blade.y=sh;stick.add(blade);s.field.add(stick);
  stick.run(A.sequence([A.rotateTo(.5,.07),A.fadeOut(.15),A.remove()]));m.node.run(A.sequence([A.scaleYTo(.35,.05),A.scaleXTo(1.3,.05),A.fadeOut(.12),A.remove()]))}
 gameUpdate(dt){for(const s of this.seats){const g=this.st[s.index];while(g.nextEvent<this.events.length&&this.events[g.nextEvent].time<=this.elapsed){this.pop(s,this.events[g.nextEvent]);g.nextEvent++}
   for(const hole of Object.keys(g.moles)){const m=g.moles[hole];if(!m.alive){delete g.moles[hole];continue}if(m.cpuAt!=null&&this.elapsed>=m.cpuAt){m.cpuAt=null;this.whack(s,m);continue}if(this.elapsed>=m.until){this.hide(m);delete g.moles[hole]}}}}
 began(seat,at){const g=this.st[seat.index];let best=null,bd=Infinity;for(const k of Object.keys(g.moles)){const m=g.moles[k];if(!m.alive)continue;const c={x:g.holes[m.hole].x,y:g.holes[m.hole].y+m.node.h*.4},d=Math.hypot(at.x-c.x,at.y-c.y);if(d<Math.max(g.cw,g.ch)*.55&&d<bd){bd=d;best=m}}
  if(best)this.whack(seat,best);else Sfx.play('tap')}
}
Arcade.register('whack',WhackGame);
})();
