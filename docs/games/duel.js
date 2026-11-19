(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const ICONS=['🏒','⚪️','🧤'],NAMES=['SCHLÄGER','BALL','HANDSCHUH'],TOTAL=7,CHOOSE=3,REVEAL=2.4;
const hit=(b,p,d)=>Math.abs(p.x-b.x)<=b.w/2+d&&Math.abs(p.y-b.y)<=b.h/2+d;
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
class DuelGame extends MiniScene{
 setupGame(){const n=this.n;this.stp='done';this.stepTime=0;this.round=0;this.picks=Array(n).fill(-1);this.lastPicks=this.picks.slice();this.cpuPickAt=Array(n).fill(1);
  this.cpuBias=this.seats.map(()=>[.8+Math.random()*.6,.8+Math.random()*.6,.8+Math.random()*.6]);this.buttons=[];this.timerLabels=[];this.roundLabels=[];this.revealNodes=[];
  for(const s of this.seats){const row=[],wide=s.w>250,top=40,area={x:-s.w/2+12,y:-s.h/2+12,w:s.w-24,h:s.h-top-60};
   for(let k=0;k<3;k++){let bw,bh,pos;if(wide){bw=(area.w-20)/3;bh=Math.min(140,area.h*.7);pos={x:area.x+bw/2+k*(bw+10),y:area.y+area.h/2}}else{bw=area.w;bh=Math.min(84,(area.h-20)/3);pos={x:area.x+area.w/2,y:area.y+area.h-bh/2-k*(bh+10)}}
    const b=new Sprite(Gfx.pill(bw,bh,alpha(s.color,.22),alpha(s.color,.8),16),bw,bh);b.x=pos.x;b.y=pos.y;b.z=10;
    const icon=label(ICONS[k],Math.min(bh*.45,46));icon.x=0;icon.y=wide?bh*.1:0;if(!wide){icon.x=-bw/2+bh*.45;icon.y=0}icon.z=1;b.add(icon);
    const t=label(NAMES[k],Math.min(15,bw*.12),'#fff');if(wide){t.x=0;t.y=-bh*.3}else{t.x=bh*.3;t.y=0}t.z=1;b.add(t);s.field.add(b);row.push(b)}
   this.buttons.push(row);const tl=label('',26,'#fff');tl.y=s.h/2-54;tl.z=20;s.field.add(tl);this.timerLabels.push(tl);
   const rl=label('',12,white(1,.6));rl.y=s.h/2-32;rl.z=20;s.node.add(rl);this.roundLabels.push(rl);
   const rn=new Node();rn.z=60;s.node.add(rn);this.revealNodes.push(rn)}}
 gameStarted(){this.startRound()}
 startRound(){this.round++;this.stp='choose';this.stepTime=0;this.picks=Array(this.n).fill(-1);
  for(const s of this.seats){this.roundLabels[s.index].text='RUNDE '+this.round+'/'+TOTAL;this.revealNodes[s.index].children.slice().forEach(c=>c.removeFromParent());
   for(const b of this.buttons[s.index]){b.alpha=1;b.setScale(1);b.cbf=0}this.cpuPickAt[s.index]=.5+Math.random()*2.1}Sfx.play('beep')}
 began(seat,at){if(this.stp!=='choose')return;const row=this.buttons[seat.index];for(let k=0;k<row.length;k++){if(hit(row[k],at,4)){this.choose(seat,k);return}}}
 choose(s,k){this.picks[s.index]=k;
  if(!s.isCPU){Sfx.play('click');Haptic.tap();this.buttons[s.index].forEach((b,j)=>{b.alpha=j===k?1:.35;b.setScale(j===k?1.06:.94)})}
  else for(const b of this.buttons[s.index])b.alpha=.35}
 cpuChoice(s){if(this.round>1&&Math.random()<s.skill*.6){const counts=[0,0,0];this.lastPicks.forEach((p,i)=>{if(i!==s.index&&p>=0)counts[p]++});
   let mp=0;for(let i=1;i<3;i++)if(counts[mp]<counts[i])mp=i;if(counts[mp]>0)return(mp+2)%3}
  const w=this.cpuBias[s.index],r=Math.random()*(w[0]+w[1]+w[2]);if(r<w[0])return 0;if(r<w[0]+w[1])return 1;return 2}
 beats(a,b){if(a<0)return false;if(b<0)return true;return b===(a+1)%3}
 gameUpdate(dt){this.stepTime+=dt;
  if(this.stp==='choose'){for(const s of this.seats)if(s.isCPU&&this.picks[s.index]<0&&this.stepTime>=this.cpuPickAt[s.index])this.choose(s,this.cpuChoice(s));
   const left=Math.max(0,CHOOSE-this.stepTime),txt=''+Math.ceil(left);for(const l of this.timerLabels)if(l.text!==txt){l.text=txt;l.setScale(1.3);l.run(A.scaleTo(1,.15))}
   const all=!this.picks.includes(-1);if(this.stepTime>=CHOOSE||(all&&this.stepTime>1))this.reveal()}
  else if(this.stp==='reveal'){if(this.stepTime>=REVEAL){if(this.round>=TOTAL){this.stp='done';this.finishGame()}else this.startRound()}}}
 reveal(){const n=this.n;this.stp='reveal';this.stepTime=0;for(const l of this.timerLabels)l.text='';const gained=Array(n).fill(0);
  for(let i=0;i<n;i++)for(let j=0;j<n;j++)if(i!==j&&this.beats(this.picks[i],this.picks[j]))gained[i]++;
  Sfx.play('whistle');
  for(const s of this.seats){for(const b of this.buttons[s.index])b.alpha=.12;const rn=this.revealNodes[s.index];rn.children.slice().forEach(c=>c.removeFromParent());
   const cw=Math.min(80,(s.w-20)/n-6),total=n*(cw+6)-6;
   this.seats.forEach((o,k)=>{const card=new Sprite(Gfx.pill(cw,cw*1.25,alpha(o.color,.85),'#fff',12),cw,cw*1.25);card.x=-total/2+cw/2+k*(cw+6);card.y=10;
    const icon=label(this.picks[k]>=0?ICONS[this.picks[k]]:'❓',cw*.45);icon.y=cw*.08;card.add(icon);
    const nm=label(o.index===s.index?'DU':o.name.slice(0,6).toUpperCase(),Math.min(11,cw*.15),'#000');nm.y=-cw*.42;card.add(nm);card.sx=.01;rn.add(card);card.run(A.sequence([A.wait(k*.08),A.scaleXTo(1,.18)]));
    if(o.index===s.index){const ring=new Sprite(Gfx.pill(cw+8,cw*1.25+8,'rgba(0,0,0,0)','#ff0',14),cw+8,cw*1.25+8);ring.x=card.x;ring.y=card.y;ring.z=-1;rn.add(ring)}});
   const g=gained[s.index],res=label(g>0?'+'+g:(this.picks[s.index]<0?'ZU LANGSAM':'0'),g>0?34:20,g>0?'#ff0':white(1,.7));res.y=-cw*.8-14;res.setScale(.2);rn.add(res);res.run(A.sequence([A.wait(.4),A.scaleTo(1,.15)]));
   if(g>0){this.addScore(s,g);if(!s.isCPU)Haptic.good()}}
  if(gained.some(g=>g>0))Sfx.play('right');else Sfx.play('miss');this.lastPicks=this.picks.slice()}
}
Arcade.register('duel',DuelGame);
})();
