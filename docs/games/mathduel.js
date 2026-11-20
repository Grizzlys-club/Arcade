(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label,Rand}=SK;
const TOTAL=10,GREEN=Theme.green;
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
class MathDuelGame extends MiniScene{
 makeQuestion(i,r){let text='',ans=0;const kind=i<3?r.int(0,1):(i<6?r.int(0,2):r.int(1,2));
  if(kind===0){const hi=i<3?9:(i<6?29:49),a=r.int(i<3?3:8,hi),b=r.int(3,i<3?9:19);text=a+' + '+b;ans=a+b}
  else if(kind===1){const a=r.int(i<3?10:18,i<3?20:50),b=r.int(3,i<3?9:17);text=a+' − '+b;ans=a-b}
  else{const a=r.int(i<6?3:6,i<6?7:12),b=r.int(i<6?3:6,i<6?9:12);text=a+' × '+b;ans=a*b}
  const opts=[ans];let tries=0;
  while(opts.length<4&&tries<50){tries++;const d=r.int(1,10)*(r.chance(.5)?1:-1);const c=ans+(kind===2&&r.chance(.5)?(r.chance(.5)?1:-1)*r.int(1,3)*(r.chance(.5)?1:(r.int(2,9)>5?10:1)):d);if(c>=0&&!opts.includes(c))opts.push(c)}
  let k=ans+11;while(opts.length<4){if(!opts.includes(k))opts.push(k);k++}
  return{text,answer:ans,options:r.shuffled(opts)}}
 setupGame(){const r=this.newRand();this.questions=[];this.panels=[];this.qi=-1;this.mstate='intro';this.timer=1.4;this.qTime=7;this.firstDone=false;
  for(let i=0;i<TOTAL;i++)this.questions.push(this.makeQuestion(i,r));this.rnd=new Rand(1+Math.floor(Math.random()*1000000));
  for(const s of this.seats){const p={seat:s,buttons:[],labels:[],rects:[],locked:false,done:false,cpuTime:0,cpuPick:0};this.panels.push(p);this.buildP(p);
   const hint=label('ERSTER = 3 PUNKTE',Math.min(20,s.w*.1),'#fff');hint.y=s.h*.1;hint.z=450;s.node.add(hint);hint.run(A.sequence([A.wait(4.2),A.fadeOut(.3),A.remove()]))}}
 buildP(p){const s=p.seat,gap=8,bw=(s.w-24-gap)/2,bh=Math.min(92,s.h*.25),y0=-s.h/2+12;
  for(let i=0;i<4;i++){const col=i%2,row=Math.floor(i/2),cx=-((bw+gap)/2)+col*(bw+gap),cy=y0+bh/2+row*(bh+gap),b=new Sprite(Gfx.pill(bw,bh,alpha(s.color,.28),s.color,18),bw,bh);b.x=cx;b.y=cy;b.z=20;s.node.add(b);
   const l=label('',Math.min(42,bw*.42),'#fff');l.z=1;b.add(l);p.buttons.push(b);p.labels.push(l);p.rects.push({x0:cx-bw/2-gap/2,y0:cy-bh/2-gap/2,x1:cx+bw/2+gap/2,y1:cy+bh/2+gap/2});b.alpha=0}
  const qy=y0+2*bh+gap+(s.h/2-50-(y0+2*bh+gap))/2+6;
  p.qLabel=label('',40,'#fff');p.qLabel.y=qy+8;p.qLabel.z=30;s.node.add(p.qLabel);p.eqLabel=label('= ?',Math.min(28,s.w*.14),s.color);p.eqLabel.y=qy-30;p.eqLabel.z=30;s.node.add(p.eqLabel);p.qLabel.alpha=0;p.eqLabel.alpha=0;
  p.barW=s.w-28;const back=new Sprite(null,p.barW,7,white(1,.15));back.y=s.h/2-36;back.z=30;s.node.add(back);p.bar=new Sprite(null,p.barW,7,GREEN);p.bar.ax=0;p.bar.x=-p.barW/2;p.bar.y=s.h/2-36;p.bar.z=31;s.node.add(p.bar);
  p.progress=label('',12,white(1,.6));p.progress.y=s.h/2-50;p.progress.z=30;s.node.add(p.progress)}
 gameStarted(){this.mstate='intro';this.timer=1.2}
 nextQuestion(){this.qi++;if(this.qi>=TOTAL){this.finishGame();this.mstate='reveal';this.timer=99;return}
  const q=this.questions[this.qi];this.qTime=Math.max(5.5,7.5-this.qi*.2);this.timer=this.qTime;this.firstDone=false;this.mstate='ask';Sfx.play('tick');
  for(const p of this.panels){const s=p.seat;p.locked=false;p.done=false;p.progress.text=(this.qi+1)+' / '+TOTAL;p.qLabel.text=q.text;p.qLabel.size=Math.min(52,(s.w-20)/(q.text.length*.64));p.qLabel.removeAllActions();p.qLabel.alpha=1;p.qLabel.setScale(.4);p.qLabel.run(A.scaleTo(1,.18));
   p.eqLabel.alpha=1;p.bar.w=p.barW;p.bar.color=GREEN;
   for(let i=0;i<4;i++){p.labels[i].text=''+q.options[i];const b=p.buttons[i];b.alpha=1;b.texture=Gfx.pill(b.w,b.h,alpha(s.color,.28),s.color,18);b.setScale(.8);b.run(A.scaleTo(1,.15));p.labels[i].color='#fff'}
   if(s.isCPU){const sk=s.skill;p.cpuTime=(.9+2.9*(1-sk)+this.qi*.05)*this.rnd.range(.7,1.3);
    if(this.rnd.chance((1-sk)*.3+.03)){let w=this.rnd.int(0,3);while(q.options[w]===q.answer)w=(w+1)%4;p.cpuPick=w}else p.cpuPick=Math.max(0,q.options.indexOf(q.answer));
    if(this.rnd.chance(Math.max(0,(.5-sk)*.15)))p.cpuTime=99}}}
 colorBtn(p,i,c){const b=p.buttons[i];b.texture=Gfx.pill(b.w,b.h,alpha(c,.55),c,18)}
 answer(p,i){if(this.mstate!=='ask'||p.locked||p.done)return;const q=this.questions[this.qi],s=p.seat,pos={x:p.buttons[i].x,y:p.buttons[i].y};
  if(q.options[i]===q.answer){p.done=true;const first=!this.firstDone,pts=first?3:1;this.firstDone=true;this.addScore(s,pts);this.colorBtn(p,i,GREEN);p.buttons[i].run(A.sequence([A.scaleTo(1.12,.07),A.scaleTo(1,.1)]));
   s.floatText('+'+pts,{x:pos.x,y:pos.y+40},first?'#ff0':GREEN,30);s.burst(pos,GREEN,first?18:8,140);Sfx.play(first?'right':'coin');if(!s.isCPU)Haptic.good();this.addStat('quiz',1,s);
   if(first&&!s.isCPU)this.stats.reaction=Math.min(this.stats.reaction==null?Infinity:this.stats.reaction,Math.floor((this.qTime-this.timer)*1000));if(first)s.flash(GREEN,.25,.3)}
  else{p.locked=true;this.colorBtn(p,i,'#f00');p.buttons[i].run(A.sequence([A.moveBy(6,0,.04),A.moveBy(-12,0,.06),A.moveBy(6,0,.04)]));p.buttons.forEach((b,j)=>{if(j!==i)b.alpha=.4});
   const lost=s.score>0;if(lost)this.addScore(s,-1);s.floatText(lost?'-1':'X',{x:pos.x,y:pos.y+40},'#f00',26);s.shake(5);Sfx.play('wrong');if(!s.isCPU)Haptic.bad()}
  if(p.done)p.buttons.forEach((b,j)=>{if(j!==i)b.alpha=.45});
  if(this.panels.every(x=>x.done||x.locked))this.startReveal()}
 startReveal(){if(this.mstate!=='ask')return;this.mstate='reveal';this.timer=1;const q=this.questions[this.qi];
  for(const p of this.panels){const k=q.options.indexOf(q.answer);if(k>=0&&!p.done){this.colorBtn(p,k,GREEN);p.buttons[k].alpha=1;p.buttons[k].run(A.sequence([A.scaleTo(1.1,.1),A.scaleTo(1,.1)]))}}}
 began(seat,at){if(this.mstate!=='ask')return;const p=this.panels[seat.index];for(let i=0;i<4;i++){const r=p.rects[i];if(at.x>=r.x0&&at.x<=r.x1&&at.y>=r.y0&&at.y<=r.y1){this.answer(p,i);return}}}
 gameUpdate(dt){this.timer-=dt;
  if(this.mstate==='intro'){if(this.timer<=0)this.nextQuestion()}
  else if(this.mstate==='ask'){const frac=Math.max(0,this.timer/this.qTime);for(const p of this.panels){p.bar.w=p.barW*frac;p.bar.color=frac<.3?'#f00':(frac<.6?Theme.orange:GREEN);if(p.seat.isCPU&&!p.done&&!p.locked&&this.qTime-this.timer>=p.cpuTime)this.answer(p,p.cpuPick)}
   if(this.mstate==='ask'&&this.timer<=0)this.startReveal()}
  else{if(this.timer<=0&&this.qi<TOTAL)this.nextQuestion()}}
}
Arcade.register('mathduel',MathDuelGame);
})();
