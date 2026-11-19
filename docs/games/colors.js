(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const WORDS=['ROT','BLAU','GRÜN','GELB','ORANGE'];
const INKS=[rgba(1,.2,.22),rgba(.25,.5,1),rgba(.2,.9,.3),rgba(1,.92,.15),rgba(1,.55,.05)];
const hit=(b,p,dx,dy)=>Math.abs(p.x-b.x)<=b.w/2+dx&&Math.abs(p.y-b.y)<=b.h/2+dy;
class ColorsGame extends MiniScene{
 setupGame(){this.duration=30;this.states=[];
  for(const s of this.seats){const st={rand:this.newRand(),item:null,streak:0,lock:0,cpuTimer:0};
   const top=s.h/2-36,bottom=-s.h/2+10,bh=Math.min(70,(top-bottom)*.22),bw=(s.w-36)/2,by=bottom+bh/2+4;
   const q=label('Passt die Farbe?',Math.min(17,s.w*.08),white(1,.8));q.y=top-14;q.z=5;s.field.add(q);
   const cardTop=top-32,cardBottom=by+bh/2+14,ch=cardTop-cardBottom,cw=s.w-28;
   const card=new Sprite(Gfx.pill(cw,ch,white(.06,.9),white(1,.25),20),cw,ch);card.y=(cardTop+cardBottom)/2;card.z=3;s.field.add(card);st.card=card;
   const word=label('',Math.min(54,s.w*.17),'#fff');word.y=card.y;word.z=6;s.field.add(word);st.word=word;
   const sl=label('',13,'#ff0');sl.y=card.y-ch/2+16;sl.z=6;s.field.add(sl);st.streakLabel=sl;
   const yes=this.button('JA ✓',bw,bh,rgba(.1,.7,.3),'#fff',Math.min(24,bw*.22));yes.x=-bw/2-6;yes.y=by;yes.z=5;s.field.add(yes);st.yes=yes;
   const no=this.button('NEIN ✕',bw,bh,rgba(.8,.15,.2),'#fff',Math.min(24,bw*.22));no.x=bw/2+6;no.y=by;no.z=5;s.field.add(no);st.no=no;
   word.text='BEREIT?';this.states.push(st)}}
 gameStarted(){for(const s of this.seats)this.nextItem(s)}
 nextItem(s){const st=this.states[s.index],r=st.rand,w=r.int(0,4);let ink=w;if(!r.chance(.5))ink=(w+r.int(1,4))%5;
  st.item={word:w,ink,match:w===ink};st.word.text=WORDS[w];st.word.color=INKS[ink];st.word.setScale(.6);st.word.run(A.scaleTo(1,.1));
  if(s.isCPU)st.cpuTimer=.6+(1-s.skill)*.9+Math.random()*.3}
 gameUpdate(dt){for(const s of this.seats){const st=this.states[s.index];if(st.lock>0)st.lock-=dt;
  if(s.isCPU&&st.item&&st.lock<=0){st.cpuTimer-=dt;if(st.cpuTimer<=0){const correct=Math.random()<.7+s.skill*.28;this.answer(s,correct?st.item.match:!st.item.match)}}}}
 answer(s,yes){const st=this.states[s.index],item=st.item;if(!item||st.lock>0)return;const btn=yes?st.yes:st.no;
  btn.run(A.sequence([A.scaleTo(.92,.05),A.scaleTo(1,.08)]));
  if(yes===item.match){st.streak++;let pts=1;if(st.streak%5===0)pts++;this.addScore(s,pts);this.addStat('hits',1,s);
   st.card.run(A.sequence([A.colorize('#0f0',.5,.05),A.custom(.2,(n,t)=>{n.cbf=.5*(1-t/.2)})]));
   s.floatText(pts>1?'+2 SERIE!':'+1',{x:0,y:st.word.y+30},pts>1?'#ff0':Theme.green,pts>1?24:20);
   st.streakLabel.text=st.streak>=3?'🔥 '+st.streak+'er Serie':'';
   if(!s.isCPU){Sfx.play(pts>1?'coin':'right');Haptic.tap()}this.nextItem(s)}
  else{st.streak=0;st.streakLabel.text='';this.setScore(s,Math.max(0,s.score-1));st.lock=.55;s.flash('#f00',.35);s.shake(4);
   s.floatText('−1',{x:0,y:st.word.y+30},'#f33',22);if(!s.isCPU){Sfx.play('wrong');Haptic.bad()}
   this.run(A.sequence([A.wait(.45),A.run(()=>{if(this.phase==='playing')this.nextItem(s)})]))}}
 began(seat,at){const st=this.states[seat.index];if(hit(st.yes,at,6,10))this.answer(seat,true);else if(hit(st.no,at,6,10))this.answer(seat,false)}
}
Arcade.register('colors',ColorsGame);
})();
